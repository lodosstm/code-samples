import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { StoreModule } from '@ngrx/store';
import { routerReducer } from './reactive/router.reducer';
import { ARouterService } from './service/router.abstract';
import { RouterService } from './service/router.service';

@NgModule({
  declarations: [],
  providers: [{ provide: ARouterService, useClass: RouterService }],
  imports: [CommonModule, StoreModule.forFeature('router', routerReducer)]
})
export class RouterModule {}
