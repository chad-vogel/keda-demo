<template>
  <article class="card">
    <header>
      <h2>{{ workload.name }}</h2>
      <span class="namespace">{{ workload.namespace }}</span>
    </header>
    <dl>
      <div>
        <dt>Desired</dt>
        <dd>{{ workload.desired }}</dd>
      </div>
      <div>
        <dt>Current</dt>
        <dd>{{ workload.current }}</dd>
      </div>
      <div>
        <dt>Ready</dt>
        <dd>{{ workload.ready }}</dd>
      </div>
    </dl>
    <footer>
      <small>Age: {{ workload.age }}</small>
    </footer>
  </article>
</template>

<script lang="ts" setup>
import type { WorkloadStatus } from "../services/kedaClient";

defineProps<{
  workload: WorkloadStatus;
}>();
</script>

<style scoped>
.card {
  background: #102738;
  border-radius: 12px;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.25);
}

header {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
}

h2 {
  margin: 0;
  font-size: 1.25rem;
}

.namespace {
  font-size: 0.85rem;
  color: #85c6ff;
}

dl {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 0.75rem;
  margin: 0;
}

dt {
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: #7aa0bd;
}

dd {
  margin: 0.25rem 0 0;
  font-size: 1.3rem;
  font-weight: 600;
}

footer {
  font-size: 0.85rem;
  color: #7aa0bd;
}
</style>
