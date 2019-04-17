import { IRoute, IPreroute } from '../types';

export const createRoute = (preroute: IPreroute): IRoute => {
  const { url, params, argumets } = preroute;

  return {
    url,
    params: {
      status: params ? params.status || '' : '',
      subtitle: params ? params.subtitle || '' : '',
      postfix: params ? params.postfix || '' : '',
      type: params ? params.type || '' : '',
      id: params ? params.id || '' : '',
      recipe: params ? params.recipe || '' : '',
      ingredient: params ? params.ingredient || '' : ''
    },
    argumets: argumets || []
  };
};

export const genereteLink = (...args: string[]): string => {
  return `/${args.reduce((acc, elem) => `${acc}/${elem}`)}`;
};

export const getLink = (base: string) => (...args: string[]) => genereteLink(base, ...args);
