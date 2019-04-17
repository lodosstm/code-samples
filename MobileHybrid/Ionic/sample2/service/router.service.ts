import { Router } from '@angular/router';
import { Injectable } from '@angular/core';
import {
  PATH,
  DEFAULT_HEADER_SUBTITLE,
  DEFAULT_PARAMETR,
  DEFAULT_TITLE_POSTFIX,
  DEFAULT_STATUS,
  DEFAULT_TYPE
} from '../const';
import { Store } from '@ngrx/store';
import { RouterPushStack } from '../reactive/router.actions';
import { IRoute, IPreroute, IRouterState } from '../types';
import { createRoute } from '../utils';
import { ARouterService } from './router.abstract';

@Injectable()
export class RouterService extends ARouterService {
  protected stack: IRoute[];

  constructor(protected router$: Router, protected store$: Store<IRouterState>) {
    super(router$, store$);
    this.clearStack();
  }

  public goToRoute(preroute: IPreroute): void {
    const route = createRoute(preroute);
    this.goToRouteByRoute(route);
  }

  public goBack(): void {
    const route = this.popAndGetHead();
    this.navigate(route);
  }

  public refreshAppRoutes(preroute: IPreroute): void {
    const route = createRoute(preroute);
    this.clearStack();
    this.goToRouteByRoute(route);
  }

  public routlessPushInStack(preroute: IPreroute): void {
    const route = createRoute(preroute);
    this.pushInStack(route);
  }

  protected setStack(newStack: IRoute[]): void {
    this.stack = newStack;
    this.store$.dispatch(new RouterPushStack({ stack: this.stack }));
  }

  protected checkDoubling(route: IRoute): boolean {
    const head = this.getStackHead();
    const headKeys = Object.keys(head);
    return headKeys.map(key => head[key] === route[key]).reduce((acc, next) => acc && next);
  }

  protected pushInStack(route: IRoute): void {
    if (!this.checkDoubling(route)) {
      this.setStack([route, ...this.stack]);
    }
  }

  protected popFromStack(): void {
    const [first, ...rest] = this.stack;
    this.setStack(rest);
  }

  protected getStackHead(): IRoute {
    return this.stack[0];
  }

  protected popAndGetHead(): IRoute {
    this.popFromStack();
    const res = this.getStackHead();
    return res;
  }

  protected clearStack(): void {
    this.setStack([this.getInitRoute()]);
  }

  protected getAngularRoute(route: IRoute): string[] {
    return [route.url];
  }

  protected navigate(route: IRoute): void {
    const path = this.getAngularRoute(route);
    this.router$.navigate(path);
  }

  protected goToRouteByRoute(route: IRoute): void {
    this.pushInStack(route);
    this.navigate(route);
  }

  protected getInitRoute(): IRoute {
    return createRoute({
      url: PATH.DEFAULT,
      params: {
        status: DEFAULT_STATUS,
        subtitle: DEFAULT_HEADER_SUBTITLE,
        postfix: DEFAULT_TITLE_POSTFIX,
        type: DEFAULT_TYPE
      },
      argumets: DEFAULT_PARAMETR
    });
  }
}
