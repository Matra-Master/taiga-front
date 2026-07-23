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
debounce = @.taiga.debounce

module = angular.module("taigaAdmin")


#############################################################################
## Changelog repositories admin (repos + branches of interest config)
#############################################################################
##
## This is admin-only config: which GitHub repo+branch pairs get recorded
## into the project's changelog on every push (see taiga.changelog.services
## on the backend). Always editable here regardless of the
## project.is_changelog_activated visual toggle (that one only hides the
## member-facing "Changelog" section, it never stops the webhook from
## writing).
#############################################################################

class ChangelogAdminController extends mixOf(taiga.Controller, taiga.PageMixin, taiga.FiltersMixin)
    @.$inject = [
        "$scope",
        "$tgRepo",
        "$tgResources",
        "$routeParams",
        "tgAppMetaService",
        "$translate",
        "tgErrorHandlingService",
        "tgProjectService"
    ]

    constructor: (@scope, @repo, @rs, @params, @appMetaService, @translate, @errorHandlingService, @projectService) ->
        bindMethods(@)

        @scope.sectionName = "ADMIN.CHANGELOG.TITLE"
        @scope.project = {}

        promise = @.loadInitialData()

        promise.then () =>
            title = @translate.instant("ADMIN.CHANGELOG.PAGE_TITLE", {projectName: @scope.project.name})
            description = @scope.project.description
            @appMetaService.setAll(title, description)

        promise.then null, @.onInitialDataError.bind(@)

        @scope.$on "changelog-repositories:reload", @.loadRepositories

    loadRepositories: ->
        return @rs.changelog.repositories.list(@scope.projectId).then (repositories) =>
            @scope.repositories = repositories

    loadProject: ->
        project = @projectService.project.toJS()

        if not project.i_am_admin
            @errorHandlingService.permissionDenied()

        @scope.projectId = project.id
        @scope.project = project
        @scope.$emit('project:loaded', project)
        return project

    loadInitialData: ->
        @.loadProject()

        return @.loadRepositories()

module.controller("ChangelogAdminController", ChangelogAdminController)


#############################################################################
## Branches <-> comma-separated-text helper (ngModel parser/formatter)
#############################################################################

ChangelogBranchesDirective = ->
    link = ($scope, $el, $attrs, $ngModel) ->
        $ngModel.$parsers.push (value) ->
            value = $.trim(value or "")
            return [] if value == ""
            return (branch.trim() for branch in value.split(",") when branch.trim() != "")

        $ngModel.$formatters.push (value) ->
            return (value or []).join(", ")

    return {
        link: link
        restrict: "EA"
        require: "ngModel"
    }

module.directive("tgChangelogBranches", ChangelogBranchesDirective)


#############################################################################
## Changelog repository row (edit / delete)
#############################################################################

ChangelogRepositoryDirective = ($repo, $confirm, $translate) ->
    link = ($scope, $el, $attrs) ->
        repository = $scope.$eval($attrs.tgChangelogRepository)

        showVisualizationMode = () ->
            $el.find(".edition-mode").addClass("hidden")
            $el.find(".visualization-mode").removeClass("hidden")

        showEditMode = () ->
            $el.find(".visualization-mode").addClass("hidden")
            $el.find(".edition-mode").removeClass("hidden")

        cancel = () ->
            showVisualizationMode()
            $scope.$apply ->
                repository.revert()

        save = debounce 2000, (target) ->
            form = target.parents("form").checksley()
            return if not form.validate()
            promise = $repo.save(repository)
            promise.then =>
                showVisualizationMode()

            promise.then null, (data) ->
                $confirm.notify("error")
                form.setErrors(data)

        $el.on "click", ".edit-changelog-repository", () ->
            showEditMode()

        $el.on "click", ".cancel-existing", () ->
            cancel()

        $el.on "click", ".edit-existing", (event) ->
            event.preventDefault()
            target = angular.element(event.currentTarget)
            save(target)

        $el.on "keyup", ".edition-mode input", (event) ->
            if event.keyCode == 13
                target = angular.element(event.currentTarget)
                save(target)
            else if event.keyCode == 27
                cancel()

        $el.on "click", ".delete-changelog-repository", () ->
            title = $translate.instant("ADMIN.CHANGELOG.DELETE")
            message = $translate.instant("ADMIN.CHANGELOG.REPOSITORY_NAME", {name: repository.full_name})

            $confirm.askOnDelete(title, message).then (askResponse) =>
                onSucces = ->
                    askResponse.finish()
                    $scope.$emit("changelog-repositories:reload")

                onError = ->
                    askResponse.finish(false)
                    $confirm.notify("error")

                $repo.remove(repository).then(onSucces, onError)

    return {link: link}

module.directive("tgChangelogRepository", ["$tgRepo", "$tgConfirm", "$translate", ChangelogRepositoryDirective])


#############################################################################
## New changelog repository form
#############################################################################

NewChangelogRepositoryDirective = ($repo, $confirm, $analytics) ->
    link = ($scope, $el, $attrs) ->
        formDOMNode = $el.find(".new-changelog-repository-form")
        addDOMNode = $el.find(".add-changelog-repository")

        initializeNewValue = ->
            $scope.newValue = {
                "full_name": ""
                "branches": []
            }

        initializeNewValue()

        $scope.$watch "repositories", (repositories) ->
            if repositories?
                if repositories.length == 0
                    formDOMNode.removeClass("hidden")
                    addDOMNode.addClass("hidden")
                    formDOMNode.find("input")[0].focus()
                else
                    formDOMNode.addClass("hidden")
                    addDOMNode.removeClass("hidden")

        save = debounce 2000, () ->
            form = formDOMNode.checksley()
            return if not form.validate()

            $scope.newValue.project = $scope.project.id
            promise = $repo.create("changelog-repositories", $scope.newValue)
            promise.then =>
                $analytics.trackEvent("changelog", "create-repository", "Create changelog repository config", 1)
                $scope.$emit("changelog-repositories:reload")
                initializeNewValue()

            promise.then null, (data) ->
                $confirm.notify("error")
                form.setErrors(data)

        formDOMNode.on "click", ".add-new", (event) ->
            event.preventDefault()
            save()

        formDOMNode.on "keyup", "input", (event) ->
            if event.keyCode == 13
                save()

        formDOMNode.on "click", ".cancel-new", (event) ->
            $scope.$apply ->
                initializeNewValue()

                if $scope.repositories.length >= 1
                    formDOMNode.addClass("hidden")

        addDOMNode.on "click", (event) ->
            formDOMNode.removeClass("hidden")
            formDOMNode.find("input")[0].focus()

    return {link: link}

module.directive("tgNewChangelogRepository", ["$tgRepo", "$tgConfirm", "$tgAnalytics", NewChangelogRepositoryDirective])
