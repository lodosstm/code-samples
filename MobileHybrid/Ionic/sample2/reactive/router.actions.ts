import { Action } from '@ngrx/store';
import { IRoute } from '../types';

export enum ActionTypes {
  ROUTER_PUSH = '[ROUTER] ROUTER_PUSH'
}

export class RouterPushStack implements Action {
  readonly type = ActionTypes.ROUTER_PUSH;

  constructor(
    public payload: {
      stack: IRoute[];
    }
  ) {}
}

export type Actions = RouterPushStack;
