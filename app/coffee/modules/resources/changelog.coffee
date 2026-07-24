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
        list: (projectId, filters={}) ->
            params = _.extend({project: projectId}, filters)
            if params.page_size == "off"
                # "no pagination" option: drop page_size and ask the back to skip pagination
                delete params.page_size
                return $repo.queryMany("changelog-entries", params)
            return $repo.queryPaginated("changelog-entries", params)
    }

    return (instance) ->
        instance.changelog = service


module = angular.module("taigaResources")
module.factory("$tgChangelogResourcesProvider", ["$tgRepo", resourceProvider])
