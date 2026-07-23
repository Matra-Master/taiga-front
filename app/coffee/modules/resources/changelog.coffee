###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
#
# Copyright (c) 2021-present Kaleidos INC
###

resourceProvider = ($repo) ->
    service = {}

    service.repositories = {
        list: (projectId) -> $repo.queryMany("changelog-repositories", {project: projectId})
    }

    service.entries = {
        list: (projectId) -> $repo.queryMany("changelog-entries", {project: projectId})
    }

    return (instance) ->
        instance.changelog = service


module = angular.module("taigaResources")
module.factory("$tgChangelogResourcesProvider", ["$tgRepo", resourceProvider])
