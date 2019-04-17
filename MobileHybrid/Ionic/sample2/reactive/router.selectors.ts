import { createFeatureSelector, createSelector } from '@ngrx/store';
import { DEFAULT_URL } from '../const';
import { IRoute, IRouterState } from '../types';
import { createRoute } from '../utils';

const featureSelector = createFeatureSelector<IRouterState>('router');

const getHead = (state: IRouterState): IRoute => state.stack[0] || createRoute({ url: DEFAULT_URL });
export const selectHead = createSelector(
  featureSelector,
  getHead
);
