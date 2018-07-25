import AppError from '../../../common/error-default';

export default class TheSameListItem extends AppError {
  public status: number = 400;
  public message: string = 'This list item already in the list';

  constructor(info?: any) {
    super(__filename, info);
  }
}
