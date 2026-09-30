# ponytail: todavía no están definidas las actividades de Kimai, así que "Start" imputa siempre a la
# actividad global "Default" (id 9 en Kimai; "0003" es su número, no su id). Poner null para volver
# al popover con el selector de actividades.
KIMAI_DEFAULT_ACTIVITY_ID = 9

KimaiTimerDirective = ($http, $tgUrls, confirmService, $translate, $timeout) ->
    getTags = (project, userStory) ->
        issueType = project.issue_types.find((issue) => issue.id == userStory.type)
        return if issueType then [issueType.name] else []

    link = ($scope, $el, $attrs) ->
        vm = $scope.vm

        # Proyecto/épica de Taiga que el back usa para resolver el proyecto de Kimai.
        getTarget = () ->
            { userStory, task } = vm
            project = $scope.$parent.$parent.project
            epics = userStory?.epics || task?.user_story_extra_info?.epics
            target = { projectId: project?.id }
            if project?.tracking_mode == "epic" && epics?.length > 0
                target.epicId = epics[0].id
            return target

        notifyError = (err) ->
            confirmService.notify("error", err.data?.error_message)

        # Texto que queda como descripción del timesheet en Kimai (mismo formato que arma el back).
        buildEntry = () ->
            { userStory, task } = vm
            usRef = task?.user_story_extra_info?.ref || userStory?.ref || ""
            taskRef = task?.ref || ""
            subject = task?.subject || userStory?.subject || ""
            return { usRef, taskRef, subject }

        describe = ({ usRef, taskRef, subject }) ->
            taskPart = if taskRef then " - ##{taskRef}" else ""
            return "TG-#{usRef}#{taskPart} #{subject}"

        $scope.openStart = () ->
            if KIMAI_DEFAULT_ACTIVITY_ID
                vm.activityId = KIMAI_DEFAULT_ACTIVITY_ID
                return $scope.startTimer()

            vm.loading = true
            vm.activityId = null
            vm.description = describe(buildEntry())
            $http.get($tgUrls.resolve("user-kimai-activities"), getTarget())
                .then (res) ->
                    projectGroup = $translate.instant("KIMAI.PROJECT_ACTIVITIES")
                    globalGroup = $translate.instant("KIMAI.GLOBAL_ACTIVITIES")
                    # Primero las del proyecto, después las globales, para que los grupos queden contiguos.
                    activities = _.sortBy(res.data, (activity) -> if activity.project then 0 else 1)
                    vm.activities = activities.map (activity) ->
                        {id: activity.id, label: activity.name, group: if activity.project then projectGroup else globalGroup}
                .catch(notifyError)
                .finally () -> vm.loading = false

        $scope.cancel = () ->
            vm.activities = null
            vm.activityId = null
            $timeout(-> $el[0].querySelector(".kimai-start .timer-button")?.focus())

        $scope.startTimer = () ->
            return if !vm.activityId
            tags = if vm.issueProject then getTags(vm.issueProject, vm.userStory) else []
            data = _.assign(getTarget(), buildEntry(), { activityId: vm.activityId, tags: tags })

            $scope.cancel()
            $http.post($tgUrls.resolve("user-start-kimai"), data)
                .then () -> confirmService.notify("success", $translate.instant("US.TIMER_START"))
                .catch(notifyError)

        $scope.stopTimer = () ->
            $http.post($tgUrls.resolve("user-stop-kimai"), {})
                .then () -> confirmService.notify("success", $translate.instant("US.TIMER_STOP"))
                .catch(notifyError)

    return {
        controller: "KimaiTimerController",
        controllerAs: "vm",
        templateUrl: "components/kimai/kimai-timer.html",
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

KimaiTimerDirective.$inject = [
    "$tgHttp",
    "$tgUrls",
    "$tgConfirm",
    "$translate",
    "$timeout"
]

angular.module("taigaComponents").directive("tgKimaiTimer", KimaiTimerDirective)
