import AppError from '../../../common/error-default';

export default class FavoriteListNameAlreadyExist extends AppError {
  public status: number = 400;
  public message: string = 'Favorite list name already exist';

  constructor(info?: any) {
    super(__filename, info);
  }
}
