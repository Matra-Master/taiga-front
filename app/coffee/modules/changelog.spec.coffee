###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
#
# Copyright (c) 2021-present Kaleidos INC
###

describe "taiga.changelogSourceRef", ->
    it "extracts the ref from a GitHub PR merge with a nested branch", ->
        message = "Merge pull request #13 from acme/backend/feature/TG-123-x\n\nTitle"
        expect(taiga.changelogSourceRef(message)).to.equal("123")

    it "extracts the ref from a GitLab merge", ->
        expect(taiga.changelogSourceRef("Merge branch 'TG-3-foo' into 'main'")).to.equal("3")

    it "ignores a TG-ref mentioned in a non-merge push", ->
        expect(taiga.changelogSourceRef("fix: arreglar TG-5")).to.equal(null)

    it "returns null for a merge of a branch without a TG-ref", ->
        expect(taiga.changelogSourceRef("Merge pull request #9 from acme/hotfix")).to.equal(null)

    it "returns null when there is no head message", ->
        expect(taiga.changelogSourceRef(null)).to.equal(null)
