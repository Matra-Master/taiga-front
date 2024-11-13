###
# This source code is licensed under the terms of the
# GNU Affero General Public License found in the LICENSE file in
# the root directory of this source tree.
#
# Copyright (c) 2021-present Kaleidos INC
###

class CreatetProjectFormController
    @.$inject = [
        "tgCurrentUserService",
        "tgProjectsService",
        "$projectUrl",
        "$location",
        "$tgNavUrls",
        "$tgAnalytics",
        "$tgConfirm"
   ]

    constructor: (@currentUserService, @projectsService, @projectUrl, @location, @navUrls, @analytics,@confirmService) ->
        @.errorList = []
        @.projectForm = {
            is_private: false
        }

        @.canCreatePublicProjects = @currentUserService.canCreatePublicProjects()
        @.canCreatePrivateProjects = @currentUserService.canCreatePrivateProjects()

        if !@.canCreatePublicProjects.valid && @.canCreatePrivateProjects.valid
            @.projectForm.is_private = true

        if @.type == 'scrum'
            @.projectForm.creation_template = 1
        else
            @.projectForm.creation_template = 2

    submit: () ->
        @.errorList = []
        if !@.projectForm.name then @.errorList.push('name')
        if !@.projectForm.description then @.errorList.push ('description')
        if !@.projectForm.clockify_id then @.errorList.push ('clockify_id')
        if(@.errorList.length == 0)
            @.formSubmitLoading = true
            @projectsService.create(@.projectForm).then (project) =>
                if(project && project.status)
                    error = project
                    @confirmService.notify("error",error.data.clockify_id[0])
                    return
                @analytics.trackEvent("project", "create", "project creation", {slug: project.get('slug'), id: project.get('id')})
                @location.url(@projectUrl.get(project))
                @currentUserService.loadProjects()

    onCancelForm: () ->
        @location.path(@navUrls.resolve("create-project"))

    canCreateProject: () ->
        if @.projectForm.is_private
            return @.canCreatePrivateProjects.valid
        else
            return @.canCreatePublicProjects.valid

    isDisabled: () ->
        return @.formSubmitLoading || !@.canCreateProject()

angular.module('taigaProjects').controller('CreateProjectFormCtrl', CreatetProjectFormController)
