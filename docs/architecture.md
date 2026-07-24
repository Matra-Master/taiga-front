# Arquitectura de taiga-front (para explorar menos, la próxima vez)

Notas de arquitectura recopiladas al implementar features de este fork, para no tener
que re-explorar el código desde cero en cada sesión. Complementa (no repite) lo que ya
está en `/CLAUDE.md`. Si algo de acá queda desactualizado, corregirlo en el mismo PR
que lo desactualiza.

## Stack y estructura general

AngularJS 1.x + CoffeeScript (`app/coffee/modules/`) + plantillas Jade
(`app/partials/`, `app/modules/**/*.jade`) + SCSS (`app/styles/`, `app/themes/`),
compilado con Gulp (`gulpfile.js`) a `dist/`. No hay TypeScript/bundler moderno: seguir
el patrón existente, no introducir Webpack/Vite/React.

Tareas de Gulp útiles para validar sin levantar el server completo (`npx gulp` arranca
el dev server + watchers, que no termina):

```bash
nvm use                 # Node 16.20.2 — con Node 24+ el build de coffee/gulp falla
npx gulp jade            # compila solo las plantillas Jade
npx gulp coffee          # compila solo CoffeeScript
npx gulp styles          # compila SCSS (lint no bloqueante, solo imprime warnings)
```

`npx gulp styles` corre `scss-lint` (stylelint) primero; los warnings (orden alfabético
de propiedades, `color-no-hex`, etc.) no rompen el build. Antes de agregar un color
nuevo, preferir las variables de `app/themes/<tema>/variables.scss` (ej. `$red-10`,
`$color-link-red`) en vez de hex literal, para no sumar más violaciones de
`color-no-hex` (ya hay debt preexistente en algunos archivos, no hace falta arreglarlo
al pasar, pero tampoco sumarle más).

## Cómo se cargan los datos de un proyecto en el admin

El objeto `project` que llega al scope de casi todos los controllers de admin viene de
`tgProjectService.project.toJS()` (`app/modules/services/project.service.coffee`) — ya
trae **todos** los arrays de valores del proyecto embebidos: `us_statuses`,
`issue_statuses`, `epic_statuses`, `task_statuses`, `points`, `issue_types`,
`priorities`, `severities`, etc. Cada status trae `id`, `name`, `slug`, `order`,
`color`, `is_closed`, `is_archived`.

Dos controllers "padre" distintos envuelven las pantallas de admin, y **no** exponen
las mismas cosas en `$scope`:

- `ProjectProfileController` (`app/coffee/modules/admin/project-profile.coffee`) — usa
  `@model.make_model("projects", project)`, así que `$scope.project` es un modelo
  "vivo" (soporta `.getAttrs()`, `.isAttributeModified()`, `.revert()`, requerido por
  `$repo.save(...)`). Además arma `$scope.usStatusList`, `$scope.issueStatusList`, etc.
  (`_.sortBy(project.xxx_statuses, "order")`). Cubre Project Profile, Default Values,
  Modules.
- `ProjectValuesSectionController` (`app/coffee/modules/admin/project-values.coffee`)
  — usa `project.toJS()` **sin** `make_model`, así que `$scope.project` es un objeto
  JS plano (NO tiene `.getAttrs()`; `$repo.save($scope.project)` fallaría acá). Tampoco
  arma las listas `usStatusList`/`issueStatusList` por sí solo. Cubre la solapa
  **Attributes** (`admin-project-values-status.jade` y hermanos: points, priorities,
  severities, types, custom-fields, tags, due-dates, kanban-power-ups).

Si una directiva nueva vive dentro de una pantalla de `ProjectValuesSectionController`
y necesita guardar un campo del proyecto, **no uses `$repo.save(project)`** (no hay
modelo wrappeado ahí) — agregá un método dedicado al resource (`$rs.projects.patch_xxx`,
patrón `service.patch_default_swimlane`/`patch_webhook_status_map` en
`app/coffee/modules/resources/projects.coffee`, un `$http.patch` directo con solo el
campo que interesa) y armá las listas de statuses vos mismo en el `link` de la
directiva a partir de `$scope.project.us_statuses`/`.issue_statuses`.

## Patrones de guardado en el admin

- `$repo.save(model)` (`app/coffee/modules/base/repository.coffee`) — PATCH genérico
  que espera un **modelo** (`model.getAttrs()`); requiere que el objeto haya pasado por
  `$tgModel.make_model(...)`. Usado por `ProjectProfileController`/
  `ProjectDefaultValuesDirective`/`ProjectModulesDirective`.
- `$repo.saveAttribute(model, "clave")` — PATCH anidado bajo una clave (`{clave:
  {...}}`), para la config de integraciones vía `project-modules` (ver `tgGithubWebhooks`
  en `third-parties.coffee`, resource `modules.coffee`
  `service.list/save` sobre `project-modules`). Es el análogo front de
  `ProjectModulesConfig` en el back.
- `$http.patch` directo en un resource (`app/coffee/modules/resources/projects.coffee`,
  ej. `patch_default_swimlane`, `patch_webhook_status_map`) — el más simple cuando no
  hace falta el ciclo completo de modelo/checksley y solo se necesita mandar 1-2 campos
  del proyecto sin depender de que `$scope.project` sea un modelo "vivo".

## Admin: cómo se arma una pantalla nueva

Agregar una subsección a un tab existente (ej. una nueva sección dentro de
Attributes/Status) es: un `div.admin-attributes-section(tg-mi-directiva)` +
`include ../includes/modules/admin/mi-partial` dentro del `.jade` de la pantalla
existente, y una directiva CoffeeScript en el archivo del módulo correspondiente
(`app/coffee/modules/admin/project-values.coffee` para Attributes,
`project-profile.coffee` para Project Profile). No hace falta `ng-controller` propio
si la directiva puede vivir en el scope heredado del controller de la pantalla.

Agregar un **tab nuevo** (nueva pantalla, no subsección) requiere tocar 4 lugares.
Ejemplo real: el tab "Automation" (Attributes → Automation, transiciones de columna por
webhook de GitHub):
1. Ruta Angular en `app/coffee/app.coffee` (`$routeProvider.when("/project/:pslug/admin/
   project-values/automation", {templateUrl: "admin/admin-project-values-automation.html",
   section: "admin"})`).
2. Nombre de nav → URL en `app/coffee/modules/base.coffee`
   (`"project-admin-project-values-automation": "/project/:project/admin/project-values/automation"`).
3. Entrada visible en el submenú (`app/partials/includes/modules/admin-submenu-project-values.jade`,
   un `li#adminmenu-values-automation` con `tg-nav="project-admin-project-values-automation:..."` —
   el sufijo de `#adminmenu-` tiene que matchear el string pasado a
   `tg-admin-navigation="values-automation"` en la pantalla, ver `nav.coffee`).
4. El partial `.jade` de la pantalla (`app/partials/admin/admin-project-values-automation.jade`),
   que declara `ng-controller="ProjectValuesSectionController"` + incluye
   `admin-menu`/`admin-submenu-project-values` + su contenido propio
   (`includes/modules/admin/webhook-transitions.jade`, con su directiva
   `tgWebhookTransitions` en `project-values.coffee`).

`select` con lista de statuses del proyecto: patrón canónico en
`app/partials/includes/modules/admin/default-values.jade` —
`select(ng-model="project.campo", ng-options="s.id as s.name for s in xStatusList")`.
Para permitir "ninguno" (select vacío = comportamiento por defecto / no-op), agregar un
`option(value="")` hijo — no está en `default-values.jade` (ahí todo campo siempre tiene
un valor), pero sí hace falta para configs opcionales como en `webhook-transitions.jade`.

**Ojo con `.submit-button`**: es una clase global (`app/styles/components/buttons.scss`,
`width: 100%`) pensada para los formularios de auth (login/registro). Si un botón de
guardado del admin necesita que `$el.find(".submit-button")` lo encuentre (para el
target de `$loading()`), agregar esa clase también lo estira a ancho completo — el resto
de los formularios del admin (`default-values.jade`, etc.) por eso **no** la usan y
simplemente dejan que `$el.find(".submit-button")` no encuentre nada (el loading spinner
queda sin target, sin romper nada). No reusar `.submit-button` fuera de auth.

## Pull Requests vinculados a un ticket

`us.pull_requests` / `issue.pull_requests` llegan **ya serializados** dentro del propio
US/Issue desde el backend (join por `(project, ref)`, ver
`taiga-back/docs/architecture.md`) — no hay ningún resource/controller CoffeeScript
propio que los cargue por separado. El markup vive duplicado (mismo HTML, misma
clases) en `app/partials/us/us-detail.jade` y `app/partials/issue/issues-detail.jade`
(sección `.ticket-pull-requests`, clases `.pr-item`, `.pr-branch`, `.pr-meta`,
`.pr-merged-pill`/`.pr-changes-pill`) — **cualquier cambio ahí hay que replicarlo en los
dos archivos**. El estado de cada PR (`pr.status`: `open`/`merged`/`changes_requested`)
decide la píldora (`ng-if`) y una clase modificadora (`ng-class`) para destacar los que
necesitan cambios; el orden (changes-requested primero) ya lo entrega el backend
ordenado, el front no reordena.

## El menú lateral de proyecto (Shadow DOM, no toques esto sin leer primero)

`tg-project-menu` (AngularJS, `app/modules/components/project-menu/`) monta
`tg-legacy-loader`, que carga un **web component Angular (Ivy) precompilado**
(`app/elements.js`, sin fuente en este repo) dentro de un Shadow DOM real
(`tg-legacy-loader.shadowRoot`), con su propio sprite SVG y hojas de estilo internas
inalcanzables desde `app/styles/`/`app/svg/sprite.svg`. Agregar un ítem al menú
requiere inyectar un nodo DOM real en
`loader.shadowRoot.querySelector('ul.menu-secondary')` (copiando el atributo
`_ngcontent-*` de un `<li>` vecino para heredar los estilos scoped Angular), y
re-ejecutar esa inyección en cada `ctrl.show()` porque ese `<ul>` se destruye y recrea
en cada cambio de proyecto/navegación. Ver `project-menu.directive.coffee`.
