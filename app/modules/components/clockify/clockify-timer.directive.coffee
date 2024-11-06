ClockifyTimerDirective = ($http, $currentUser, $tgUrls) ->
    link = ($scope, $el, $attrs) ->

        $scope.startTimer = () ->
            userStorieData = $scope.$parent.$$watchers[4].last
            proyectName = userStorieData.project_extra_info.name
            clockifyKey = $currentUser.getUser().get("clockify_key")
            
            data = {subject: userStorieData.subject, ref: userStorieData.ref, proyectName, clockifyKey}
            $http.post($tgUrls.resolve("user-start-clocki"), data)

        $scope.stopTimer = () ->
            userStorieData = $scope.$parent.$$watchers[4].last
            proyectName = userStorieData.project_extra_info.name
            clockifyKey = $currentUser.getUser().get("clockify_key")
            
            data = {subject: userStorieData.subject, ref: userStorieData.ref, proyectName, clockifyKey}
            $http.post($tgUrls.resolve("user-stop-clocki"), data)

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
    "$tgUrls"
]

angular.module("taigaComponents").directive("tgClockifyTimer", ClockifyTimerDirective)
