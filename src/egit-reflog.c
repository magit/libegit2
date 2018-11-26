#include <string.h>

#include "git2.h"

#include "egit.h"
#include "interface.h"
#include "egit-reflog.h"


// =============================================================================
// Constructors

EGIT_DOC(reflog_read, "REPO REFNAME", "Open the reflog for REFNAME in REPO.");
emacs_value egit_reflog_read(emacs_env *env, emacs_value _repo, emacs_value _refname)
{
    EGIT_ASSERT_REPOSITORY(_repo);
    EM_ASSERT_STRING(_refname);

    git_repository *repo = EGIT_EXTRACT(_repo);
    char *refname = EM_EXTRACT_STRING(_refname);
    git_reflog *reflog;
    int retval = git_reflog_read(&reflog, repo, refname);
    free(refname);
    EGIT_CHECK_ERROR(retval);

    return egit_wrap(env, EGIT_REFLOG, reflog, NULL);
}


// =============================================================================
// Getters

EGIT_DOC(reflog_entry_byindex, "REFLOG N", "Get the Nth entry in REFLOG.");
emacs_value egit_reflog_entry_byindex(emacs_env *env, emacs_value _reflog, emacs_value _index)
{
    EGIT_ASSERT_REFLOG(_reflog);
    EM_ASSERT_INTEGER(_index);
    git_reflog *reflog = EGIT_EXTRACT(_reflog);
    ptrdiff_t index = EM_EXTRACT_INTEGER(_index);
    const git_reflog_entry *entry = git_reflog_entry_byindex(reflog, index);

    if (!entry) {
        em_signal_args_out_of_range(env, index);
        return em_nil;
    }

    return egit_wrap(env, EGIT_REFLOG_ENTRY, entry, EM_EXTRACT_USER_PTR(_reflog));
}

EGIT_DOC(reflog_entry_committer, "REFLOG-ENTRY", "Get the committer of REFLOG-ENTRY.");
emacs_value egit_reflog_entry_committer(emacs_env *env, emacs_value _entry)
{
    EGIT_ASSERT_REFLOG_ENTRY(_entry);
    const git_reflog_entry *entry = EGIT_EXTRACT(_entry);
    const git_signature *sig = git_reflog_entry_committer(entry);

    git_signature *new;
    int retval = git_signature_dup(&new, sig);
    EGIT_CHECK_ERROR(retval);
    return egit_wrap(env, EGIT_SIGNATURE, new, NULL);
}

EGIT_DOC(reflog_entry_id, "REFLOG-ENTRY SIDE",
         "Get the ID of REFLOG-ENTRY. SIDE is either `old' or `new'.");
emacs_value egit_reflog_entry_id(emacs_env *env, emacs_value _entry, emacs_value side)
{
    EGIT_ASSERT_REFLOG_ENTRY(_entry);
    const git_reflog_entry *entry = EGIT_EXTRACT(_entry);

    const git_oid *oid;
    if (EM_EQ(side, em_new))
        oid = git_reflog_entry_id_new(entry);
    else if (EM_EQ(side, em_old))
        oid = git_reflog_entry_id_old(entry);
    else {
        em_signal_wrong_value(env, side);
        return em_nil;
    }

    const char *oid_s = git_oid_tostr_s(oid);
    return EM_STRING(oid_s);
}

EGIT_DOC(reflog_entry_message, "REFLOG-ENTRY", "Get the message of REFLOG-ENTRY.");
emacs_value egit_reflog_entry_message(emacs_env *env, emacs_value _entry)
{
    EGIT_ASSERT_REFLOG_ENTRY(_entry);
    const git_reflog_entry *entry = EGIT_EXTRACT(_entry);
    const char *msg = git_reflog_entry_message(entry);
    return EM_STRING(msg);
}

EGIT_DOC(reflog_entrycount, "REFLOG", "Get the number of entries in REFLOG");
emacs_value egit_reflog_entrycount(emacs_env *env, emacs_value _reflog)
{
    EGIT_ASSERT_REFLOG(_reflog);
    git_reflog *reflog = EGIT_EXTRACT(_reflog);
    return EM_INTEGER(git_reflog_entrycount(reflog));
}