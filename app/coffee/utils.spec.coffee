###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
#
# Copyright (c) 2021-present Kaleidos INC
###

describe "taiga.branchName", ->
    it "transposes accents and ñ instead of stripping them", ->
        branch = taiga.branchName({ref: 108, subject: "Añadir botón"})
        expect(branch).to.equal("TG-108-anadir-boton")

    it "formats a task branch with a literal #", ->
        branch = taiga.branchName({ref: 12, subject: "Fix login"}, 3, 12)
        expect(branch).to.equal("TG-3-#12-fix-login")

    it "does not leave a trailing dash on an empty subject", ->
        branch = taiga.branchName({ref: 5, subject: ""})
        expect(branch).to.equal("TG-5")
