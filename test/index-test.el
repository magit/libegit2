(ert-deftest index ()
  (with-temp-dir path
    (init)
    (commit-change "file1" "content")
    (commit-change "file2" "more content")
    (write "file2" "changes")
    (write "file3" "more changes")
    (write "file4" "even more changes")
    (add "file2" "file3")
    (let* ((repo (libgit-repository-open path))
           (index (libgit-repository-index repo)))
      (should (= 3 (libgit-index-entrycount index)))
      (let* ((i1 (libgit-index-get-byindex index 0))
             (i2 (libgit-index-get-byindex index 1))
             (i3 (libgit-index-get-byindex index 2))
             (head (libgit-reference-name-to-id repo "HEAD"))
             (commit (libgit-commit-lookup repo head))
             (tree (libgit-commit-tree commit)))
        (should (string= "file1" (libgit-index-entry-path i1)))
        (should (string= "file2" (libgit-index-entry-path i2)))
        (should (string= "file3" (libgit-index-entry-path i3)))
        (should-not (libgit-index-entry-stage i1))
        (should-not (libgit-index-entry-stage i2))
        (should-not (libgit-index-entry-stage i3))
        (should (string= (libgit-index-entry-id i1)
                         (caddr (libgit-tree-entry-byname tree "file1"))))
        (should-not (string= (libgit-index-entry-id i2)
                             (caddr (libgit-tree-entry-byname tree "file2"))))))))

(ert-deftest index-conflicts ()
  (with-temp-dir path
    (init)
    (commit-change "file" "alpha")
    (create-branch "A")
    (commit-change "file" "beta")
    (checkout "master")
    (create-branch "B")
    (commit-change "file" "gamma")
    (run-fail "git" "merge" "A")
    (let* ((repo (libgit-repository-open path))
           (index (libgit-repository-index repo)))
      (should (= 3 (libgit-index-entrycount index)))
      (let ((i1 (libgit-index-get-byindex index 0))
            (i2 (libgit-index-get-byindex index 1))
            (i3 (libgit-index-get-byindex index 2)))
        (should (string= "file" (libgit-index-entry-path i1)))
        (should (string= "file" (libgit-index-entry-path i2)))
        (should (string= "file" (libgit-index-entry-path i3)))
        (should (eq 'base (libgit-index-entry-stage i1)))
        (should (eq 'ours (libgit-index-entry-stage i2)))
        (should (eq 'theirs (libgit-index-entry-stage i3)))
        (should (eq 'base (libgit-index-entry-stage (libgit-index-get-bypath index "file" 'base))))
        (should (eq 'ours (libgit-index-entry-stage (libgit-index-get-bypath index "file" 'ours))))
        (should (eq 'theirs (libgit-index-entry-stage (libgit-index-get-bypath index "file" 'theirs))))
        (should-not (libgit-index-get-bypath index "file"))
        (let ((conflicts (libgit-index-conflict-get index "file")))
          (should (eq 'base (libgit-index-entry-stage (car conflicts))))
          (should (eq 'ours (libgit-index-entry-stage (cadr conflicts))))
          (should (eq 'theirs (libgit-index-entry-stage (caddr conflicts)))))))))
