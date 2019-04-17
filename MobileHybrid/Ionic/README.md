# Samples of Ionic with Angular

## Ionic modal window

This component uses input callbacks & ionic directives for simple modal window browsing.

### Files

* [index](sample1/index.ts)
* [component](sample1/edit.component.ts)
* [style](sample1/edit.component.scss)
* [template](sample1/edit.component.html)

## Router service

This service uses various Typescript/Angular/Ionic elements for creating specifiс case router behavior.
Router service is SOLID encapsulated module with an abstract token in DI. Service implements simple reactive redux-like data flow by using ngrx/rxjs.

### Files

* [index](sample2/index.ts)
* [module](sample2/router.module.ts)
* [types](sample2/types/index.ts)
* [utils](sample2/utils/index.ts)
* [const](sample2/const/index.ts)
* [service](sample2/service/router.service.ts)
* [abstract](sample2/service/router.abstract.ts)
* [state](sample2/reactive/router.state.ts)
* [actions](sample2/reactive/router.actions.ts)
* [reducer](sample2/reactive/router.reducer.ts)
* [selectors](sample2/reactive/router.selectors.ts)
