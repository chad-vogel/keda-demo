<template>
  <main>
    <section class="hero">
      <div>
        <h1>KEDA Demo Dashboard</h1>
        <p>
          Lightweight Vue 3 viewer that surfaces replica counts and metrics for the sample workloads
          deployed in the demo cluster (CPU API, queue worker, Azure Functions).
        </p>
        <div class="cta">
          <label>
            API Base URL
            <input v-model="apiBase" placeholder="http://localhost:8080" />
          </label>
          <button @click="refresh" :disabled="loading">
            {{ loading ? "Refreshing…" : "Refresh data" }}
          </button>
        </div>
      </div>
      <aside>
        <ul>
          <li>
            <strong>CPU demo</strong>
            <span>./scripts/keda-demo.sh deploy-cpu-demo</span>
          </li>
          <li>
            <strong>Queue demo</strong>
            <span>./scripts/keda-demo.sh deploy-queue-demo</span>
          </li>
          <li>
            <strong>Functions demo</strong>
            <span>./scripts/keda-demo.sh deploy-functions-demo</span>
          </li>
        </ul>
      </aside>
    </section>

    <section class="grid">
      <WorkloadCard v-for="workload in workloads" :key="workload.name" :workload="workload" />
    </section>

    <section class="metrics">
      <h2>Live Metrics</h2>
      <div class="metrics-grid">
        <article v-for="series in metrics" :key="series.resource">
          <header>{{ series.resource }}</header>
          <ul>
            <li v-for="sample in series.samples" :key="sample.timestamp">
              <span>{{ new Date(sample.timestamp).toLocaleTimeString() }}</span>
              <span>{{ sample.value.toFixed(2) }} {{ sample.unit }}</span>
            </li>
          </ul>
        </article>
      </div>
    </section>
  </main>
</template>

<script lang="ts" setup>
import { onMounted, reactive, ref, watch } from "vue";
import WorkloadCard from "./components/WorkloadCard.vue";
import type { MetricSample, WorkloadStatus } from "./services/kedaClient";

interface MetricSeries {
  resource: string;
  samples: MetricSample[];
}

const apiBase = ref(import.meta.env.VITE_KEDA_DEMO_API ?? "http://localhost:8080");
const loading = ref(false);
const workloads = reactive<WorkloadStatus[]>([]);
const metrics = reactive<MetricSeries[]>([]);

async function fetchJson<T>(path: string): Promise<T> {
  const response = await fetch(`${apiBase.value}${path}`);
  if (!response.ok) {
    throw new Error(`Request failed: ${response.status}`);
  }
  return response.json() as Promise<T>;
}

async function refresh() {
  loading.value = true;
  try {
    const [workloadData, metricData] = await Promise.all([
      fetchJson<WorkloadStatus[]>("/api/workloads"),
      fetchJson<Record<string, MetricSample[]>>("/api/metrics")
    ]);

    workloads.splice(0, workloads.length, ...workloadData);
    metrics.splice(
      0,
      metrics.length,
      ...Object.entries(metricData).map(([resource, samples]) => ({
        resource,
        samples
      }))
    );
  } catch (error) {
    console.error(error);
  } finally {
    loading.value = false;
  }
}

onMounted(refresh);
watch(apiBase, refresh);
</script>

<style scoped>
main {
  display: flex;
  flex-direction: column;
  gap: 3rem;
  padding: 3rem clamp(1.5rem, 5vw, 4rem);
}

.hero {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 2rem;
  align-items: start;
}

.hero h1 {
  font-size: clamp(2rem, 3vw, 2.6rem);
  margin: 0 0 0.5rem;
}

.hero p {
  margin: 0;
  color: #b9d4ea;
  line-height: 1.6;
}

.cta {
  margin-top: 1.5rem;
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  align-items: flex-end;
}

label {
  display: flex;
  flex-direction: column;
  font-size: 0.85rem;
  color: #93b8d6;
  gap: 0.35rem;
}

input {
  padding: 0.6rem 0.75rem;
  border: 1px solid rgba(132, 189, 240, 0.35);
  border-radius: 8px;
  background: rgba(12, 27, 40, 0.6);
  color: inherit;
}

button {
  padding: 0.65rem 1.5rem;
  border-radius: 999px;
  border: none;
  background: linear-gradient(135deg, #4da3ff, #7dd3fc);
  color: #04121c;
  font-weight: 600;
  cursor: pointer;
}

button:disabled {
  opacity: 0.6;
  cursor: progress;
}

.hero aside {
  background: rgba(16, 39, 56, 0.8);
  border-radius: 12px;
  padding: 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.hero aside ul {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.hero aside li {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.hero aside strong {
  font-size: 1rem;
}

.hero aside span {
  font-family: "SFMono-Regular", ui-monospace, SFMono, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
  font-size: 0.85rem;
  color: #93b8d6;
}

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 1.5rem;
}

.metrics {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.metrics h2 {
  margin: 0;
}

.metrics-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 1rem;
}

.metrics-grid article {
  background: rgba(16, 39, 56, 0.7);
  border-radius: 12px;
  padding: 1rem;
}

.metrics-grid header {
  font-weight: 600;
  margin-bottom: 0.75rem;
  color: #7dd3fc;
}

.metrics-grid ul {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.metrics-grid li {
  display: flex;
  justify-content: space-between;
  font-family: "SFMono-Regular", ui-monospace, SFMono, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
  font-size: 0.8rem;
  color: #b9d4ea;
}
</style>
