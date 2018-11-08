#include "egit.h"

#ifndef EGIT_DIFF_H
#define EGIT_DIFF_H

EGIT_DEFUN(diff_index_to_index, emacs_value _repo, emacs_value _old_index,
           emacs_value _new_index, emacs_value _opts);
EGIT_DEFUN(diff_index_to_workdir, emacs_value _repo, emacs_value _index,
           emacs_value _opts);
EGIT_DEFUN(diff_tree_to_index, emacs_value _repo, emacs_value _old_tree,
           emacs_value _index, emacs_value _opts);
EGIT_DEFUN(diff_tree_to_tree, emacs_value _repo, emacs_value _old_tree,
           emacs_value _new_tree, emacs_value _opts);
EGIT_DEFUN(diff_tree_to_workdir, emacs_value _repo, emacs_value _old_tree,
           emacs_value _opts);
EGIT_DEFUN(diff_tree_to_workdir_with_index, emacs_value _repo,
           emacs_value _old_tree, emacs_value _opts);

#endif /* EGIT_DIFF_H */
