ClockifyTimerDirective = ($http, $currentUser, $tgUrls, confirmService, $translate) ->
    link = ($scope, $el, $attrs) ->
        $scope.startTimer = () ->
            userStorieData = $scope.$parent.$$watchers[4].last
            projectData = $scope.$parent.$parent.project
            clockifyKey = $currentUser.getUser().get("clockify_key")
            
            data = { subject: userStorieData.subject, ref: userStorieData.ref, clockifyKey }
            if projectData && projectData.clockify_id
                projectClockifyId = projectData.clockify_id
                data = Object.assign({}, data, { projectClockifyId })
            response = $http.post($tgUrls.resolve("user-start-clocki"), data)

            response.then () =>
                confirmService.notify("success",$translate.instant("US.TIMER_START"))

            response.catch (err) =>
                confirmService.notify("error",err.data.error_message)

        $scope.stopTimer = () ->
            userStorieData = $scope.$parent.$$watchers[4].last
            proyectName = userStorieData.project_extra_info.name
            clockifyKey = $currentUser.getUser().get("clockify_key")
            
            data = {subject: userStorieData.subject, ref: userStorieData.ref, proyectName, clockifyKey}
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
    }

ClockifyTimerDirective.$inject = [
    "$tgHttp",
    "tgCurrentUserService",
    "$tgUrls",
    "$tgConfirm",
    "$translate"
]

angular.module("taigaComponents").directive("tgClockifyTimer", ClockifyTimerDirective)
