###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
#
# Copyright (c) 2021-present Kaleidos INC
###

taiga = @.taiga
mixOf = @.taiga.mixOf
bindMethods = @.taiga.bindMethods

module = angular.module("taigaChangelog", [])


#############################################################################
## Changelog (member-facing, read-only)
#############################################################################
##
## Lists what the GitHub push webhook has recorded for this project's
## configured repositories/branches (see taiga.changelog on the backend).
## Gated by project.is_changelog_activated: the webhook keeps recording
## regardless, this is purely the "is it visible to the team" switch.
#############################################################################

class ChangelogController extends mixOf(taiga.Controller, taiga.PageMixin, taiga.FiltersMixin)
    @.$inject = [
        "$scope",
        "$tgResources",
        "$routeParams",
        "tgAppMetaService",
        "$translate",
        "tgErrorHandlingService",
        "tgProjectService"
    ]

    constructor: (@scope, @rs, @params, @appMetaService, @translate, @errorHandlingService, @projectService) ->
        bindMethods(@)

        @scope.sectionName = "CHANGELOG.SECTION_NAME"
        @scope.project = {}
        @scope.repositoriesById = {}

        promise = @.loadInitialData()

        promise.then () =>
            title = @translate.instant("CHANGELOG.PAGE_TITLE", {projectName: @scope.project.name})
            description = @scope.project.description
            @appMetaService.setAll(title, description)

        promise.then null, @.onInitialDataError.bind(@)

    loadRepositories: ->
        return @rs.changelog.repositories.list(@scope.projectId).then (repositories) =>
            @scope.repositories = repositories
            byId = {}
            for repository in repositories
                byId[repository.id] = repository.full_name
            @scope.repositoriesById = byId

    loadEntries: ->
        return @rs.changelog.entries.list(@scope.projectId).then (entries) =>
            @scope.entries = entries

    loadProject: ->
        project = @projectService.project.toJS()

        if not project.is_changelog_activated
            @errorHandlingService.notFound()

        @scope.projectId = project.id
        @scope.project = project
        @scope.$emit('project:loaded', project)
        return project

    loadInitialData: ->
        @.loadProject()
        @.loadEntries()

        return @.loadRepositories()

module.controller("ChangelogController", ChangelogController)
