import { Router } from '@angular/router';
import { Store } from '@ngrx/store';
import { IRoute, IPreroute, IRouterState } from '../types';

export abstract class ARouterService {
  constructor(protected router$: Router, protected store$: Store<IRouterState>) {}

  public abstract goToRoute(preroute: IPreroute): void;

  public abstract goBack(): void;

  public abstract refreshAppRoutes(preroute: IPreroute): void;

  public abstract routlessPushInStack(preroute: IPreroute): void;

  protected abstract getInitRoute(): IRoute;

  protected abstract setStack(newStack: IRoute[]): void;

  protected abstract checkDoubling(route: IRoute): boolean;

  protected abstract pushInStack(route: IRoute): void;

  protected abstract popFromStack(): void;

  protected abstract getStackHead(): IRoute;

  protected abstract popAndGetHead(): IRoute;

  protected abstract clearStack(): void;

  protected abstract getAngularRoute(route: IRoute): string[];

  protected abstract navigate(route: IRoute): void;

  protected abstract goToRouteByRoute(route: IRoute): void;
}
