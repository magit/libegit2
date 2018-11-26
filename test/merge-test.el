(ert-deftest merge-analysis-ff ()
  (let (id)
    (with-temp-dir path
      (init)
      (commit-change "a" "abcdef")
      (create-branch "newbranch")
      (commit-change "a" "ghijkl")
      (commit-change "a" "mnopqrs")
      (checkout "master")
      (let* ((repo (libgit-repository-open path))
             (ref (libgit-reference-dwim repo "newbranch"))
             (ann (libgit-annotated-commit-from-ref repo ref)))
        (should (equal '((normal fastforward) . nil)
                       (libgit-merge-analysis repo (list ann))))))))

(ert-deftest merge-analysis-up-to-date ()
  (let (id)
    (with-temp-dir path
      (init)
      (commit-change "a" "abcdef")
      (create-branch "newbranch")
      (checkout "master")
      (let* ((repo (libgit-repository-open path))
             (ref (libgit-reference-dwim repo "newbranch"))
             (ann (libgit-annotated-commit-from-ref repo ref)))
        (should (equal '((up-to-date) . nil)
                       (libgit-merge-analysis repo (list ann))))))))

(ert-deftest merge-analysis-normal ()
  (let (id)
    (with-temp-dir path
      (init)
      (commit-change "a" "abcdef")
      (create-branch "newbranch")
      (commit-change "a" "ghijkl")
      (checkout "master")
      (commit-change "a" "mnopqrs")
      (let* ((repo (libgit-repository-open path))
             (ref (libgit-reference-dwim repo "newbranch"))
             (ann (libgit-annotated-commit-from-ref repo ref)))
        (should (equal '((normal) . nil)
                       (libgit-merge-analysis repo (list ann))))))))

(ert-deftest merge-analysis-preference ()
  (let (id)
    (with-temp-dir path
      (init)
      (commit-change "a" "abcdef")
      (create-branch "newbranch")
      (commit-change "a" "ghijkl")
      (checkout "master")
      (commit-change "a" "mnopqrs")
      (let* ((repo (libgit-repository-open path))
             (config (libgit-repository-config repo))
             (ref (libgit-reference-dwim repo "newbranch"))
             (ann (libgit-annotated-commit-from-ref repo ref)))
        (let ((trans (libgit-config-lock config)))
          (libgit-config-set-bool config "merge.ff" nil)
          (libgit-transaction-commit trans))
        (should (equal '((normal) . no-fastforward)
                       (libgit-merge-analysis repo (list ann))))
        (let ((trans (libgit-config-lock config)))
          (libgit-config-set-string config "merge.ff" "only")
          (libgit-transaction-commit trans))
        (should (equal '((normal) . fastforward-only)
                       (libgit-merge-analysis repo (list ann))))))))

(ert-deftest merge-base ()
  (let (id)
    (with-temp-dir path
      (init)
      (commit-change "a" "abcdef")
      (setq id (run-nnl "git" "rev-parse" "HEAD"))
      (create-branch "newbranch")
      (commit-change "a" "ghijkl")
      (checkout "master")
      (commit-change "a" "mnopqrs")
      (let* ((repo (libgit-repository-open path))
             (id1 (libgit-reference-name-to-id repo "refs/heads/master"))
             (id2 (libgit-reference-name-to-id repo "refs/heads/newbranch")))
        (should (string= id (libgit-merge-base repo (list id1 id2))))))))

(ert-deftest merge-base-octopus ()
  (let (id)
    (with-temp-dir path
      (init)
      (commit-change "a" "abcdef")
      (setq id (run-nnl "git" "rev-parse" "HEAD"))
      (create-branch "newbranch")
      (commit-change "a" "ghijkl")
      (checkout "master")
      (create-branch "otherbranch")
      (commit-change "a" "mnopqr")
      (checkout "master")
      (commit-change "a" "tuvwxy")
      (let* ((repo (libgit-repository-open path))
             (id1 (libgit-reference-name-to-id repo "refs/heads/master"))
             (id2 (libgit-reference-name-to-id repo "refs/heads/newbranch"))
             (id3 (libgit-reference-name-to-id repo "refs/heads/otherbranch")))
        (should (string= id (libgit-merge-base-octopus repo (list id1 id2 id3))))
        (should (string= id (libgit-merge-base repo (list id1 id2 id3))))))))

(ert-deftest merge-bases ()
  (let (id)
    (with-temp-dir path
      (init)
      (commit-change "a" "abcdef")
      (commit-change "a" "ghijkl")
      (commit-change "a" "mnopqrs")
      (setq id (run-nnl "git" "rev-parse" "HEAD"))
      (create-branch "newbranch")
      (commit-change "a" "tuvwxy")
      (checkout "master")
      (commit-change "a" "123456")
      (let* ((repo (libgit-repository-open path))
             (id1 (libgit-reference-name-to-id repo "refs/heads/master"))
             (id2 (libgit-reference-name-to-id repo "refs/heads/newbranch")))
        (should (equal (list id)
                       (libgit-merge-bases repo (list id1 id2))))))))

(ert-deftest merge-no-conflicts ()
  (let (id-merge id-head blobid-a blobid-b blobid-b)
    (with-temp-dir path
      (init)
      (commit-change "a" "abcdef")
      (setq blobid-a (run-nnl "git" "rev-parse" "HEAD:a"))
      (create-branch "otherbranch")
      (commit-change "b" "ghijkl")
      (setq blobid-b (run-nnl "git" "rev-parse" "HEAD:b"))
      (setq id-merge (run-nnl "git" "rev-parse" "HEAD"))
      (checkout "master")
      (commit-change "c" "mnopqr")
      (setq blobid-c (run-nnl "git" "rev-parse" "HEAD:c"))
      (setq id-head (run-nnl "git" "rev-parse" "HEAD"))
      (let* ((repo (libgit-repository-open path))
             (ref (libgit-reference-dwim repo "otherbranch"))
             (ann (libgit-annotated-commit-from-ref repo ref)))
        (should-not (libgit-repository-state repo))
        (libgit-merge repo (list ann))
        (should (eq 'merge (libgit-repository-state repo)))
        (let ((index (libgit-repository-index repo)))
          (should (= 3 (libgit-index-entrycount index)))
          (should (string= blobid-a (libgit-index-entry-id (libgit-index-get-bypath index "a"))))
          (should (string= blobid-b (libgit-index-entry-id (libgit-index-get-bypath index "b"))))
          (should (string= blobid-c (libgit-index-entry-id (libgit-index-get-bypath index "c"))))
          (should-not (libgit-index-conflicts-p index))
          (should (string= id-merge (read-file-nnl ".git/MERGE_HEAD")))
          (should (string= id-head (read-file-nnl ".git/ORIG_HEAD")))
          ;; Merge not committed yet
          (should (string= id-head (run-nnl "git" "rev-parse" "HEAD"))))))))
