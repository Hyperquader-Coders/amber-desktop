# amber-desktop — the suite's metapackage. No payload: the Depends line is the
# product. packaging/control.in is the only thing worth editing here.
VERSION = 0.1.0
# The finished package. amberlinux-apt ingests it via `make deb-path`;
# amberlinux-apt/docs/PACKAGING.md is the shared target contract.
DEB = dist/amber-desktop_$(VERSION)-1_all.deb
BRANCH ?= main
REMOTE ?= origin
ROOT_COMMIT_MSG ?= Initial amber-desktop

.PHONY: deps check ci lint deb deb-path deb-install deb-remove clean push force-push check-no-agent-files

deps:
	sudo apt install dpkg-dev lintian shellcheck

# Every name in Depends/Recommends/Suggests must be a package the archive
# actually carries, or `apt install amber-desktop` fails for the user rather
# than here.
# The local archive first, so a dev sees what they are about to publish. Otherwise
# the deployed one, which is public — a runner with no checkout still checks.
ARCHIVE ?= ../amberlinux-apt
PACKAGES_URL ?= https://apt.amberlinux.org/dists/amber/main/binary-amd64/Packages
check:
	@if [ -d "$(ARCHIVE)/db" ]; then \
		have=$$(reprepro -b "$(ARCHIVE)" --list-format '$${package}\n' list amber | sort -u); \
	else \
		have=$$(curl -fsSL "$(PACKAGES_URL)" | sed -n 's/^Package: //p' | sort -u) \
			|| { echo "check: no archive at $(ARCHIVE) and $(PACKAGES_URL) unreachable"; exit 1; }; \
	fi; \
	miss=0; \
	for p in $$(sed -n 's/^\(Depends\|Recommends\|Suggests\): //p' packaging/control.in \
		| tr ',' '\n' | sed 's/^ *//; s/[ (].*//' | grep .); do \
		printf '%s\n' "$$have" | grep -qx "$$p" \
			|| { echo "check: $$p is named here but not in the archive"; miss=1; }; \
	done; \
	test $$miss -eq 0 && echo "check: every named package is in the archive"

ci: check lint
	@echo "CI OK"

lint: deb
	@if command -v lintian >/dev/null; then lintian --no-tag-display-limit -L '>=pedantic' $(DEB); \
	else echo "lintian not installed — skipping (apt install lintian)"; fi
	@if command -v shellcheck >/dev/null; then \
		git ls-files | while read -r f; do \
			case "$$f" in *.sh|*.bash) echo "$$f";; \
			*) head -1 "$$f" 2>/dev/null | grep -q '^#!.*sh' && echo "$$f";; esac; \
		done | xargs -r shellcheck --severity=warning && echo "shellcheck OK"; \
	else echo "shellcheck not installed — skipping (apt install shellcheck)"; fi

deb:
	rm -rf out/deb
	install -D -m644 LICENSE out/deb/usr/share/doc/amber-desktop/LICENSE
	install -D -m644 packaging/debian/copyright out/deb/usr/share/doc/amber-desktop/copyright
	install -D -m644 packaging/lintian-overrides out/deb/usr/share/lintian/overrides/amber-desktop
	gzip -9n < packaging/debian/changelog > out/deb/usr/share/doc/amber-desktop/changelog.Debian.gz
	find out/deb -type d -exec chmod 755 {} +
	find out/deb -type f ! -perm -111 -exec chmod 644 {} +
	mkdir -p out/deb/DEBIAN
	cd out/deb && find . -type f -not -path './DEBIAN/*' -printf '%P\n' | sort | xargs md5sum > DEBIAN/md5sums
	sed -e 's/@VERSION@/$(VERSION)/' \
		-e "s/@SIZE@/$$(du -sk out/deb --exclude=DEBIAN | cut -f1)/" \
		packaging/control.in > out/deb/DEBIAN/control
	mkdir -p dist
	dpkg-deb --build --root-owner-group out/deb $(DEB)

# Where `make deb` puts the package: one absolute path, nothing else.
deb-path:
	@echo "$(CURDIR)/$(DEB)"

deb-install: deb
	sudo apt install --reinstall ./$(DEB)

deb-remove:
	sudo apt remove amber-desktop

clean:
	rm -rf out dist

push:
	git push "$(REMOTE)" "$(BRANCH)"

# Rewrite the whole tree as one signed root commit and force-push it. The suite's
# repos carry no history until the first official release.
# Agent files are never published. Two ways they get in: already tracked, or
# present-and-unignored when `git add -A` below sweeps the whole tree. Both are
# checked here, because a squashed history shows no file being added — a stray
# path simply appears in the root commit as though it always belonged.
check-no-agent-files:
	@bad=$$(git ls-files | grep -E '(^|/)(\.mcp\.json|\.claude/|\.claude-amber/)' || true); \
	if [ -n "$$bad" ]; then \
		echo "agent files are tracked and must not be published:"; \
		printf '  %s\n' $$bad; \
		echo "fix: git rm -r --cached <path>, then add it to .gitignore"; \
		exit 2; \
	fi
	@for p in .mcp.json .claude .claude-amber; do \
		if [ -e "$$p" ] && ! git check-ignore -q "$$p"; then \
			echo "$$p exists and is not gitignored — 'git add -A' would publish it"; \
			echo "fix: add $$p to .gitignore"; \
			exit 2; \
		fi; \
	done
	@echo "no agent files staged for publication"

force-push: check check-no-agent-files
	@test -z "$$(git status --porcelain)" || { \
		echo "Working tree is dirty. Commit, stash, or revert changes first."; \
		exit 2; \
	}
	@orig_branch="$$(git branch --show-current)"; \
	tmp_branch="root-squash-$$(date +%s)"; \
	git checkout --orphan "$$tmp_branch"; \
	git add -A; \
	git commit -S -m "$(ROOT_COMMIT_MSG)"; \
	git branch -D "$(BRANCH)" 2>/dev/null || true; \
	git branch -m "$(BRANCH)"; \
	git push --force --set-upstream "$(REMOTE)" "$(BRANCH)"; \
	echo "Rewrote $$orig_branch as signed root commit on $(REMOTE)/$(BRANCH)."
