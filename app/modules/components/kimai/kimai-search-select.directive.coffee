# Combo con buscador: items = [{id, label, group?}], model = id elegido, onSelect(item) opcional.
KimaiSearchSelectDirective = ($timeout) ->
    link = ($scope, $el) ->
        vm = $scope.vm
        vm.search = ""
        vm.active = 0
        vm.open = !!vm.startOpen

        # Al abrir, el campo pasa a ser el buscador: enfocarlo para escribir directo.
        focusSearch = () -> $timeout(-> $el.find("input")[0]?.focus())
        # Al cerrar, devolver el foco al campo para no perder la navegación con teclado.
        focusField = () -> $timeout(-> $el.find("button")[0]?.focus())

        # Mantener visible el ítem marcado al moverse con las flechas por una lista larga.
        scrollToActive = () ->
            $timeout(-> $el[0].querySelector(".kimai-combo-option.is-active")?.scrollIntoView({block: "nearest"}))

        vm.openList = () ->
            vm.open = true
            vm.active = 0
            focusSearch()

        focusSearch() if vm.open

        vm.selectedLabel = () ->
            _.find(vm.items, {id: vm.model})?.label

        vm.pick = (item) ->
            return if !item
            vm.model = item.id
            vm.search = ""
            vm.active = 0
            vm.open = false
            focusField()
            vm.onSelect({item: item})

        vm.keydown = (event) ->
            filtered = vm.filtered or []
            switch event.key
                when "Escape"
                    # Solo cierra la lista; que el Escape no cierre también el popover que la contiene.
                    event.stopPropagation()
                    vm.open = false
                    focusField()
                when "ArrowDown"
                    vm.active = Math.max(Math.min(vm.active + 1, filtered.length - 1), 0)
                    scrollToActive()
                when "ArrowUp"
                    vm.active = Math.max(vm.active - 1, 0)
                    scrollToActive()
                when "Enter"
                    vm.pick(filtered[vm.active])
                else
                    vm.active = 0
                    return
            event.preventDefault()

    return {
        controller: () ->,
        controllerAs: "vm",
        bindToController: true,
        templateUrl: "components/kimai/kimai-search-select.html",
        link: link,
        scope: {
            items: "=",
            model: "=?",
            onSelect: "&",
            placeholder: "@",
            searchPlaceholder: "@",
            startOpen: "=?"
        },
    }

KimaiSearchSelectDirective.$inject = ["$timeout"]

angular.module("taigaComponents").directive("tgKimaiSearchSelect", KimaiSearchSelectDirective)
