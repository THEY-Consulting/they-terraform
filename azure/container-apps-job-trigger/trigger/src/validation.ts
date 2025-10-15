import { type Static, type TSchema } from '@sinclair/typebox';
import { TypeCompiler } from '@sinclair/typebox/compiler';

/**
 * Exporting validation schema builder (Type function) and typescript type
 * creation helper (Static type, TSchema type) here so that every package can create their own
 * validations using the same typebox version.
 */
export * from '@sinclair/typebox';

/**
 * Validates data against the given typebox representation of the expected type.
 * Should be used when having contact with the outside world (API calls, DB
 * calls, parsing files, etc..) to ensure that the data we get looks like we
 * expect it to. Logs/stringifies the first 10 (set limit to change this) errors
 * by default, to avoid out of memory issues when stringifying the errors for a
 * huge schema with many errors.
 *
 * @throws Error if data is invalid
 */
export const validateData = <T extends TSchema>(
  data: unknown,
  schema: T,
  limit: number = 10,
): Static<T> => {
  const compiledSchema = TypeCompiler.Compile(schema);

  if (!compiledSchema.Check(data)) {
    const compilerErrors = Array.from(compiledSchema.Errors(data));
    throw new Error(
      `got ${compilerErrors.length} errors. First ${limit}: ${JSON.stringify(
        compilerErrors.slice(0, 10),
      )}`,
    );
  }

  return data;
};

export const parseAndValidate = <T extends TSchema>(resultJson: string, schema: T): Static<T> => {
  const parsed = JSON.parse(resultJson) as unknown;
  return validateData(parsed, schema);
};
