import { Type, type Static } from '@sinclair/typebox';

export type Logger = {
  log: (msg: string) => void;
  warn: (msg: string, err?: unknown) => void;
  error: (msg: string, err?: unknown) => void;
  debug: (msg: string) => void;
};

export type JobExecutionResult = {
  executionId: string;
  executionName: string;
};

export const EnvironmentVarSchema = Type.Object({
  name: Type.String(),
  value: Type.Optional(Type.String()),
  secretRef: Type.Optional(Type.String()),
});

export type EnvironmentVar = Static<typeof EnvironmentVarSchema>;

export const ContainerResourcesSchema = Type.Object({
  cpu: Type.Number(),
  memory: Type.String(),
});

export const JobContainerSchema = Type.Object({
  name: Type.String(),
  image: Type.String(),
  resources: ContainerResourcesSchema,
  env: Type.Array(EnvironmentVarSchema),
});

export const JobConfigurationSchema = Type.Object({
  properties: Type.Object({
    template: Type.Object({
      containers: Type.Array(JobContainerSchema),
    }),
  }),
});

export const JobExecutionResponseSchema = Type.Object({
  id: Type.String(),
  name: Type.String(),
});

export const JobParamsSchema = Type.Record(
  Type.String(),
  Type.Union([Type.String(), Type.Number(), Type.Boolean(), Type.Null(), Type.Undefined()]),
);

export type JobParams = Static<typeof JobParamsSchema>;
