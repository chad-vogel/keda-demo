export interface WorkloadStatus {
  name: string;
  namespace: string;
  desired: number;
  current: number;
  ready: number;
  age: string;
}

export interface MetricSample {
  resource: string;
  value: number;
  unit: string;
  timestamp: string;
}

const defaultBaseUrl = import.meta.env.VITE_KEDA_DEMO_API ?? "http://localhost:8080";

async function getJson<T>(path: string): Promise<T> {
  const response = await fetch(`${defaultBaseUrl}${path}`);
  if (!response.ok) {
    throw new Error(`Request failed: ${response.status}`);
  }
  return response.json() as Promise<T>;
}

export function fetchWorkloads(): Promise<WorkloadStatus[]> {
  return getJson<WorkloadStatus[]>("/api/workloads");
}

export function fetchMetrics(resource: string): Promise<MetricSample[]> {
  const encoded = encodeURIComponent(resource);
  return getJson<MetricSample[]>(`/api/metrics?resource=${encoded}`);
}
