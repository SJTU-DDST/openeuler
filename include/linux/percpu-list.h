/*
 * Per-cpu list
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * (C) Copyright 2016 Hewlett-Packard Enterprise Development LP
 *
 * Authors: Waiman Long <waiman.long@hpe.com>
 */
#ifndef __LINUX_PERCPU_LIST_H
#define __LINUX_PERCPU_LIST_H

#include <linux/spinlock.h>
#include <linux/list.h>
#include <linux/percpu.h>

/*
 * include/linux/percpu-list.h
 *
 * A per-cpu list protected by a per-cpu spinlock.
 *
 * The pcpu_list_head structure contains the spinlock, the other
 * pcpu_list_node structures only contains a pointer to the spinlock in
 * pcpu_list_head.
 */
struct pcpu_list_head {
	struct list_head list;
	spinlock_t lock;
};

#define PCPU_LIST_HEAD_INIT(name)				\
	{							\
		.list.prev = &name.list,			\
		.list.next = &name.list,			\
		.list.lock = __SPIN_LOCK_UNLOCKED(name),	\
	}

/*
 * Per-cpu list iteration state
 */
struct pcpu_list_state {
	int			 cpu;
	spinlock_t		*lock;
	struct list_head	*head;	/* List head of current per-cpu list */
	struct pcpu_list_node	*curr;
	struct pcpu_list_node	*next;
};

#define PCPU_LIST_STATE_INIT()			\
	{					\
		.cpu  = -1,			\
		.lock = NULL,			\
		.head = NULL,			\
		.curr = NULL,			\
		.next = NULL,			\
	}

#define DEFINE_PCPU_LIST_STATE(s)		\
	struct pcpu_list_state s = PCPU_LIST_STATE_INIT()

static inline void init_pcpu_list_state(struct pcpu_list_state *state)
{
	state->cpu  = -1;
	state->lock = NULL;
	state->head = NULL;
	state->curr = NULL;
	state->next = NULL;
}

/*
 * Next per-cpu list entry
 */
#define pcpu_list_next_entry(pos, member) list_next_entry(pos, member.list)

/*
 * Per-cpu node data structure
 */
struct pcpu_list_node {
	struct list_head list;
	spinlock_t *lockptr;
};

#define PCPU_LIST_NODE_INIT(name)		\
	{					\
		.list.prev = &name.list,	\
		.list.next = &name.list,	\
		.list.lockptr = NULL		\
	}

static inline void init_pcpu_list_node(struct pcpu_list_node *node)
{
	INIT_LIST_HEAD(&node->list);
	node->lockptr = NULL;
}

static inline void free_pcpu_list_head(struct pcpu_list_head **ppcpu_head)
{
	free_percpu(*ppcpu_head);
	*ppcpu_head = NULL;
}

/*
 * Check if all the per-cpu lists are empty
 */
static inline bool pcpu_list_empty(struct pcpu_list_head *pcpu_head)
{
	int cpu;

	for_each_possible_cpu(cpu)
		if (!list_empty(&per_cpu_ptr(pcpu_head, cpu)->list))
			return false;
	return true;
}

/*
+ * Helper function to find the first entry of the next per-cpu list
+ * It works somewhat like for_each_possible_cpu(cpu).
+ *
+ * Return: true if the entry is found, false if all the lists exhausted
+ */
static __always_inline bool
__pcpu_list_next_cpu(struct pcpu_list_head *head, struct pcpu_list_state *state)
{
	if (state->lock)
		spin_unlock(state->lock);
next_cpu:
	/*
	 * for_each_possible_cpu(cpu)
	 */
	state->cpu = cpumask_next(state->cpu, cpu_possible_mask);
	if (state->cpu >= nr_cpu_ids)
		return false;	/* All the per-cpu lists iterated */

	state->head = &per_cpu_ptr(head, state->cpu)->list;
	if (list_empty(state->head))
		goto next_cpu;

	state->lock = &per_cpu_ptr(head, state->cpu)->lock;
	spin_lock(state->lock);
	state->curr = list_entry(state->head->next,
				 struct pcpu_list_node, list);
	return true;
}

/*
 * Iterate to the next entry of the group of per-cpu lists
 *
 * Return: true if the next entry is found, false if all the entries iterated
 */
static inline bool pcpu_list_iterate(struct pcpu_list_head *head,
				     struct pcpu_list_state *state)
{
	/*
	 * Find next entry
	 */
	if (state->curr)
		state->curr = list_next_entry(state->curr, list);

	if (!state->curr || (&state->curr->list == state->head)) {
		/*
		 * The current per-cpu list has been exhausted, try the next
		 * per-cpu list.
		 */
		if (!__pcpu_list_next_cpu(head, state))
			return false;
	}
#ifdef CONFIG_DEBUG_SPINLOCK
	WARN_ON(state->curr->lockptr != state->lock);
#endif
	return true;	/* Continue the iteration */
}

/*
 * Iterate to the next entry of the group of per-cpu lists and safe
 * against removal of list_entry
 *
 * Return: true if the next entry is found, false if all the entries iterated
 */
static inline bool pcpu_list_iterate_safe(struct pcpu_list_head *head,
					  struct pcpu_list_state *state)
{
	/*
	 * Find next entry
	 */
	if (state->curr) {
		state->curr = state->next;
		state->next = list_next_entry(state->next, list);
	}

	if (!state->curr || (&state->curr->list == state->head)) {
		/*
		 * The current per-cpu list has been exhausted, try the next
		 * per-cpu list.
		 */
		if (!__pcpu_list_next_cpu(head, state))
			return false;
		state->next = list_next_entry(state->curr, list);
	}
#ifdef CONFIG_DEBUG_SPINLOCK
	WARN_ON(state->curr->lockptr != state->lock);
#endif
	return true;	/* Continue the iteration */
}

extern void pcpu_list_add(struct pcpu_list_node *node,
			  struct pcpu_list_head *head);
extern void pcpu_list_del(struct pcpu_list_node *node);
extern int  init_pcpu_list_head(struct pcpu_list_head **ppcpu_head);

#endif /* __LINUX_PERCPU_LIST_H */