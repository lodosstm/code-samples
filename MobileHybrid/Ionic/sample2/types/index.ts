export interface IRouterState {
  stack: IRoute[];
}

export interface IRoute {
  url: string;
  params: IRouteParams;
  argumets: string[];
}

export interface IRouteParams {
  status: string;
  subtitle: string;
  postfix: string;
  type: string;
  id: string;
  recipe: string;
  ingredient: string;
}

export interface IPreroute {
  url: string;
  params?: IPrerouteParams;
  argumets?: string[];
}

export interface IPrerouteParams {
  status?: string;
  subtitle?: string;
  postfix?: string;
  type?: string;
  id?: string;
  recipe?: string;
  ingredient?: string;
}
