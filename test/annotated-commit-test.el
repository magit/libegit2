(ert-deftest annotated-commit-from-ref ()
  (with-temp-dir path
    (init)
    (commit-change "test" "foo")
    (let* ((repo (libgit-repository-open path))
           (ref  (libgit-reference-lookup repo "HEAD"))
           (ann  (libgit-annotated-commit-from-ref repo ref)))
      (should (libgit-annotated-commit-p ann)))))

(ert-deftest annotated-commit-from-fetchhead ()
  (with-temp-dir remote-path
    (init)
    (commit-change "test" "aaa" "Commit A")
    (let* ((remote-repo (libgit-repository-open remote-path))
	   (remote-id (libgit-reference-name-to-id remote-repo "HEAD")))

      (with-temp-dir local-path
        (init)
	(commit-change "test" "bbb" "Commit B")
	(run "git" "fetch" remote-path)

	(let* ((local-repo (libgit-repository-open local-path))
               (ann  (libgit-annotated-commit-from-fetchhead
		      local-repo
		      "refs/heads/master"
		      remote-path
		      remote-id)))
	  (should (libgit-annotated-commit-p ann)))))))

