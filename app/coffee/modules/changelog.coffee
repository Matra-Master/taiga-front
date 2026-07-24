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
        "$element",
        "$tgResources",
        "$routeParams",
        "$tgLocation",
        "tgAppMetaService",
        "$translate",
        "tgErrorHandlingService",
        "tgProjectService"
    ]

    defaultPageSize: "25"
    loadEntriesRequests: 0

    constructor: (@scope, @element, @rs, @params, @location, @appMetaService, @translate, @errorHandlingService, @projectService) ->
        bindMethods(@)

        # Pikaday (tg-date-selector) writes the picked date straight into the input's
        # DOM value without firing input/change events, so ng-model can't see it.
        # Read the fields directly on "Apply", same trick lightboxes.coffee uses for due_date.
        @.prettyDateFormat = @translate.instant("COMMON.PICKERDATE.FORMAT")

        @scope.sectionName = "CHANGELOG.SECTION_NAME"
        @scope.project = {}
        @scope.repositoriesById = {}

        params = @location.search()
        @scope.filterRepository = params.repository or ""
        @scope.filterBranch = params.branch or ""
        @scope.filterDateFrom = if params.created_date__gte \
            then moment(params.created_date__gte).format(@.prettyDateFormat) else ""
        @scope.filterDateTo = if params.created_date__lte \
            then moment(params.created_date__lte).subtract(1, "day").format(@.prettyDateFormat) else ""
        @scope.pageSize = params.page_size or @.defaultPageSize

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
            branches = []
            for repository in repositories
                byId[repository.id] = repository.full_name
                branches = branches.concat(repository.branches or [])
            @scope.repositoriesById = byId
            @scope.branches = _.sortBy(_.uniq(branches))

    loadEntries: ->
        filters = @location.search()
        if not filters.page_size
            filters = _.extend({page_size: @.defaultPageSize}, filters)

        @.loadEntriesRequests += 1
        requestIndex = @.loadEntriesRequests

        promise = @rs.changelog.entries.list(@scope.projectId, filters)
        promise.then (data) =>
            return if requestIndex != @.loadEntriesRequests

            if _.isArray(data)
                # "no pagination" response: a plain array with everything in it
                @scope.entries = data
                @scope.count = data.length
                @scope.page = 1
                @scope.paginatedBy = null
            else
                @scope.entries = data.models
                @scope.page = data.current
                @scope.count = data.count
                @scope.paginatedBy = data.paginatedBy

        return promise

    numPages: ->
        return 0 if not @scope.paginatedBy
        return Math.ceil(@scope.count / @scope.paginatedBy)

    changeRepository: (id) ->
        @.unselectFilter("page")
        if id then @.replaceFilter("repository", id) else @.unselectFilter("repository")
        @.loadEntries()

    changeBranch: (name) ->
        @.unselectFilter("page")
        if name then @.replaceFilter("branch", name) else @.unselectFilter("branch")
        @.loadEntries()

    applyDateFilters: ->
        dateFrom = @element.find(".changelog-filter-date-from").val()
        dateTo = @element.find(".changelog-filter-date-to").val()

        @.unselectFilter("page")

        if dateFrom
            @.replaceFilter("created_date__gte", moment(dateFrom, @.prettyDateFormat).format("YYYY-MM-DD"))
        else
            @.unselectFilter("created_date__gte")

        if dateTo
            # created_date__lte is parsed as midnight of that day on the back, so bump it a day
            # forward to make the "to" date inclusive of the whole day the user picked.
            upperBound = moment(dateTo, @.prettyDateFormat).add(1, "day").format("YYYY-MM-DD")
            @.replaceFilter("created_date__lte", upperBound)
        else
            @.unselectFilter("created_date__lte")

        @.loadEntries()

    changePageSize: (value) ->
        @.unselectFilter("page")
        @.replaceFilter("page_size", value)
        @.loadEntries()

    prevPage: ->
        return if @scope.page <= 1
        @.selectFilter("page", @scope.page - 1)
        @.loadEntries()

    nextPage: ->
        return if @scope.page >= @.numPages()
        @.selectFilter("page", @scope.page + 1)
        @.loadEntries()

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
