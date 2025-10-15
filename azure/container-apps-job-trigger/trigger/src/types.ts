export type Logger = {
  log: (msg: string) => void;
  warn: (msg: string, err?: unknown) => void;
  error: (msg: string, err?: unknown) => void;
  debug: (msg: string) => void;
};

export type Api = {
  baseUrl: string;
  apiVersion: string;
  accessToken: string;
}

export type JobParams = Record<string, string>;

export type EnvironmentVar = {
  name: string;
  value?: string;
  secretRef?: string;
};

export type Container = {
  name: string;
  image: string;
  resources: {
    cpu: string;
    memory: string;
  };
  env: EnvironmentVar[];
}

export type JobConfigResponse = {
  properties: {
    template: {
      containers: Container[];
    };
  };
};

export type ExecutionResponse = {
  id: string;
  name: string;
}
