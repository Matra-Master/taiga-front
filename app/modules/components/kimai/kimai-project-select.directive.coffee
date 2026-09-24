# Desplegable con los proyectos de Kimai visibles para el token del usuario actual.
KimaiProjectSelectDirective = ($http, $tgUrls, currentUserService) ->
    link = ($scope) ->
        vm = $scope.vm
        vm.hasToken = !!currentUserService.getUser()?.get("kimai_token")
        return if !vm.hasToken

        $http.get($tgUrls.resolve("user-kimai-projects"))
            .then (res) ->
                vm.projects = res.data.map (project) ->
                    label = if project.parentTitle then "#{project.parentTitle} / #{project.name}" else project.name
                    {id: project.id, label: label}
            .catch (err) -> vm.error = err.data?.error_message

    return {
        controller: () ->,
        controllerAs: "vm",
        bindToController: true,
        templateUrl: "components/kimai/kimai-project-select.html",
        link: link,
        scope: {
            model: "="
        },
    }

KimaiProjectSelectDirective.$inject = [
    "$tgHttp",
    "$tgUrls",
    "tgCurrentUserService"
]

angular.module("taigaComponents").directive("tgKimaiProjectSelect", KimaiProjectSelectDirective)
