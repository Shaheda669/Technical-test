# devops.technical-tests.ci-cd

Implement a CI/CD pipeline using a tool of your choice (Jenkins, CircleCI, GitLab CI, etc.).

- The pipeline should include stages to deploy/configure frontend, backend, and Redis applications:
  - build 
    - this stage should build the files contained in ./containerization
  - test
    - this stage should use `mocha` for the frontend, and `testing` for the backend applications
  - deploy
    - this stage should update the deployment image version in a running kubernetes cluster
