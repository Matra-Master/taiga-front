ClockifyTimerDirective = ($http, $currentUser, $tgUrls, confirmService, $translate) ->
    clockifyTagIds = {
        "BF-Visual": "6703e94c0ccb9e4db57aaa1f"
        "BF-QA": "6703e981ce255b6aed515b6d"
        "BF-Prod": "6744e0c77d300d3841215319"
    }

    getTags = (project, userStory)->
        issueType = project.issue_types.find((issue) => issue.id == userStory.type)
        return [clockifyTagIds[issueType.name]]

    link = ($scope, $el, $attrs) ->
        $scope.startTimer = () ->
            { userStory, task } = $scope.vm
            tagIds = []
            if($scope.vm.issueProject)
                tagIds = getTags($scope.vm.issueProject, userStory)
            project = $scope.$parent.$parent.project
            clockifyKey = $currentUser.getUser().get("clockify_key")

            subject = task?.subject || userStory?.subject || ""
            taskRef = task?.ref || ""
            usRef = task?.user_story_extra_info?.ref || userStory?.ref || ""

            data = { subject, usRef, taskRef, tagIds, clockifyKey }

            if project?.clockify_id
                projectClockifyId = project.clockify_id
                data = Object.assign({}, data, { projectClockifyId })
            response = $http.post($tgUrls.resolve("user-start-clocki"), data)

            response.then () =>
                confirmService.notify("success",$translate.instant("US.TIMER_START"))

            response.catch (err) =>
                confirmService.notify("error",err.data.error_message)

        $scope.stopTimer = () ->
            clockifyKey = $currentUser.getUser().get("clockify_key")
            
            data = { clockifyKey }
            response = $http.post($tgUrls.resolve("user-stop-clocki"), data)

            response.then () =>
                confirmService.notify("success",$translate.instant("US.TIMER_STOP"))

            response.catch (err) =>
                confirmService.notify("error",err.data.error_message)

    return {
        scope: true,
        controller: "ClockifyTimerController",
        controllerAs: "vm",
        templateUrl: "components/clockify/clockify-timer.html",
        link: link
        bindToController: true,
        scope: {
            start: "@",
            stop: "@",
            userStory: "=",
            task: "=",
            removeStopButton: "="
            issueProject: "="
        },
    }

ClockifyTimerDirective.$inject = [
    "$tgHttp",
    "tgCurrentUserService",
    "$tgUrls",
    "$tgConfirm",
    "$translate"
]

angular.module("taigaComponents").directive("tgClockifyTimer", ClockifyTimerDirective)
