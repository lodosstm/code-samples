import { ActionTypes, Actions } from './router.actions';
import { initState } from './router.state';
import { IRouterState } from '../types';

export function routerReducer(state = initState, action: Actions): IRouterState {
  switch (action.type) {
    case ActionTypes.ROUTER_PUSH:
      return {
        ...state,
        stack: action.payload.stack
      };
      
    default: {
      return state;
    }
  }
}
