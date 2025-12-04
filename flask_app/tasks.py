import json
import os
from celery import Celery
from flask_app import queries
from flask_app.model import get_db

rbmq_user = os.environ.get('RABBITMQ_USER')    # guest
rbmq_host = os.environ.get('RABBITMQ_HOST')    # rabbitmq

celery = Celery(
    'tasks',
    broker=f'pyamqp://{rbmq_user}@{rbmq_host}//',
    backend='rpc://'
)

celery.conf.task_routes = {
    "small_task": {"queue": "small"},
    "large_task": {"queue": "large"},
}

def fib(n: int):
    """recursive fibonacci, worst possible performance."""
    if n == 1:
        return 0
    elif n == 2:
        return 1
    else:
        return fib(n - 1) + fib(n - 2)

def fib_small(n: int):
    if n > 20:
        n = 20
    return fib(n)


def fib_large(n: int):
    return fib(n)

@celery.task(name="small_task", task_reject_on_worker_lost=True)
def fib_small_job(job_uuid: str):
    """Process small-number workload."""
    db = get_db()
    queries.set_job_started(db, job_uuid)

    job = queries.get_job(db, job_uuid)
    payload = json.loads(job.task)

    ans = fib_small(payload["n"])

    queries.set_job_completed(db, job_uuid)
    queries.set_job_result(db, job_uuid, str(ans))


@celery.task(name="large_task", task_reject_on_worker_lost=True)
def fib_large_job(job_uuid: str):
    """Process large-number workload."""
    db = get_db()
    queries.set_job_started(db, job_uuid)

    job = queries.get_job(db, job_uuid)
    payload = json.loads(job.task)

    ans = fib_large(payload["n"])

    queries.set_job_completed(db, job_uuid)
    queries.set_job_result(db, job_uuid, str(ans))