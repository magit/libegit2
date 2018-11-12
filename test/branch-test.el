(ert-deftest branch-create ()
  (with-temp-dir path
    (init)
    (commit-change "test" "content")
    (let ((repo (libgit-repository-open path)))
      (should (libgit-branch-create repo "new-branch" "HEAD"))
      (should-error (libgit-branch-create repo "new-branch" "HEAD"))))
  (with-temp-dir path
    (init)
    (commit-change "test" "content")
    (run "git" "branch" "second")
    (run "git" "checkout" "second")
    (commit-change "test2" "content2")
    (let ((repo (libgit-repository-open path)))
      (should-error (libgit-branch-create repo "master" "second"))
      (should (libgit-branch-create repo "master" "second" t)))))

(ert-deftest branch-create-from-annotated ()
  (with-temp-dir path
    (init)
    (commit-change "test" "content")
    (let ((repo (libgit-repository-open path)))
      (should (libgit-branch-create-from-annotated repo "new-branch" "HEAD"))
      (should-error (libgit-branch-create-from-annotated repo "new-branch" "HEAD"))))
  (with-temp-dir path
    (init)
    (commit-change "test" "content")
    (run "git" "branch" "second")
    (run "git" "checkout" "second")
    (commit-change "test2" "content2")
    (let ((repo (libgit-repository-open path)))
      (should-error (libgit-branch-create-from-annotated repo "master" "second"))
      (should (libgit-branch-create-from-annotated repo "master" "second" t)))))

(ert-deftest branch-lookup ()
  (with-temp-dir path
    (init)
    (commit-change "test" "content")
    (run "git" "branch" "second")
    (let ((repo (libgit-repository-open path)))
      (should (libgit-branch-lookup repo "master"))
      (should (libgit-branch-lookup repo "second"))
      (should (libgit-branch-lookup repo "second"))
      (should-error (libgit-branch-lookup repo "third"))
      (should-error (libgit-branch-lookup repo "master" t)))))

(ert-deftest branch-delete ()
  (with-temp-dir path
    (init)
    (commit-change "test" "content")
    (run "git" "branch" "second")
    (let* ((repo (libgit-repository-open path))
           (masterref (libgit-branch-lookup repo "master"))
           (secondref (libgit-branch-lookup repo "second")))
      (should-error (libgit-branch-delete masterref))
      (libgit-branch-delete secondref))))

(ert-deftest branch-checked-out-p ()
  (with-temp-dir path
    (init)
    (commit-change "test" "content")
    (run "git" "branch" "second")
    (let* ((repo (libgit-repository-open path))
           (masterref (libgit-branch-lookup repo "master"))
           (secondref (libgit-branch-lookup repo "second")))
      (should (libgit-branch-checked-out-p masterref))
      (should-not (libgit-branch-checked-out-p secondref)))))

(ert-deftest branch-head-p ()
  (with-temp-dir path
    (init)
    (commit-change "test" "content")
    (run "git" "branch" "second")
    (let* ((repo (libgit-repository-open path))
           (masterref (libgit-branch-lookup repo "master"))
           (secondref (libgit-branch-lookup repo "second")))
      (should (libgit-branch-head-p masterref))
      (should-not (libgit-branch-head-p secondref)))))

(ert-deftest branch-name ()
  (with-temp-dir path
    (init)
    (commit-change "test" "content")
    (run "git" "branch" "second")
    (let* ((repo (libgit-repository-open path))
           (ref (libgit-branch-lookup repo "second")))
      (should-error (libgit-branch-name nil))
      (should (string= "second" (libgit-branch-name ref))))))

(ert-deftest branch-remote-name ()
  (with-temp-dir (path path-upstream)
    (in-dir path-upstream
      (init)
      (commit-change "test" "content"))
    (in-dir path
      (init)
      (commit-change "test" "content")
      (run "git" "remote" "add" "-f" "upstream" (concat "file://" path-upstream)))
    (let ((repo (libgit-repository-open path)))
      (should-error (libgit-branch-remote-name nil "refs/remotes/upstream/master"))
      (should-error (libgit-branch-remote-name repo nil))
      (should-error (libgit-branch-remote-name repo "master"))
      (should (string= "upstream" (libgit-branch-remote-name repo "refs/remotes/upstream/master"))))))

(ert-deftest branch-upstream-name ()
  (with-temp-dir (path path-upstream)
    (in-dir path-upstream
      (init)
      (commit-change "test" "content"))
    (in-dir path
      (init)
      (commit-change "test" "content")
      (run "git" "remote" "add" "-f" "upstream" (concat "file://" path-upstream))
      (run "git" "branch" "second" "upstream/master"))
    (let ((repo (libgit-repository-open path)))
      (should-error (libgit-branch-upstream-name nil "refs/heads/second"))
      (should-error (libgit-branch-upstream-name repo nil))
      (should-error (libgit-branch-upstream-name repo "refs/heads/master"))
      (should (string= "refs/remotes/upstream/master" (libgit-branch-upstream-name repo "refs/heads/second"))))))
