# Codebase
- [ ] Update `VERSION_` variables in `lib/config.py`
- [ ] Update `protocol_changes.json` (as necessary)
- [ ] Update Counterparty package versions in the `requirements.txt` files
- [ ] Update Counterparty Docker images versions in the `docker-compose.yml` files
- [ ] Review all open pull requests
- [ ] Write release notes
- [ ] Create pull request against `master`
- [ ] Ensure all tests pass in CI
- [ ] Merge PR into `master`
- [ ] Tag and sign release, copying release notes from the codebase
- [ ] Rebase `gh-pages` against `master`
- [ ] Upload (signed) package to PyPi
	* `sudo python3 setup.py sdist build`
	* `sudo python3 setup.py sdist upload -r pypi`
- [ ] Publish bootstrap files
- [ ] Publish Docker images
- [ ] Update documentation


# Announcements

- [ ] [Official Forums](https://forums.counterparty.io/t/new-version-announcements-counterparty-and-counterpartyd/363))
- [ ] Mailing list
- [ ] Telegram
- [ ] Twitter
