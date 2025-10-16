import type { Config } from './config';
import { Logger } from './types';

export type App = {
  config: Config;
  logger: Logger;
};

export const newApp = async (cfg: Config, logger: Logger): Promise<App> => {
  return {
    config: cfg,
    logger,
  };
};
