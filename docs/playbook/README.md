# playbook documentation index

## 1. purpose and scope
Index for flow-oriented implementation playbooks.

## 2. architecture overview
### high-level design
Playbooks document cross-service workflows for activity, auth, and community domains.

### key design patterns
- scenario-based implementation guides.

### data contracts/models
- references to domain-specific contract documents.

### external integrations
- backend services and frontend feature modules.

## 3. code structure and key components
### file map
- `activity-flow/README.md`
- `auth-flow/README.md`
- `community-flow/README.md`

### entry points
- read this index first and open target flow guide.

### critical logic
- not applicable.

### configuration
- not applicable.

## 4. development and maintenance guidelines
### setup instructions
- update playbooks with each major flow change.

### testing strategy
- include validation evidence and commands per flow.

### code standards
- maintain consistent section headings and link style.

### common pitfalls
- stale references after route or module changes.

### logging and monitoring
- include key logs and metrics for each flow.

## 5. deployment and operations
### build/deployment steps
- flow docs should include release smoke checks.

### runtime requirements
- depends on involved services.

### health checks
- include health endpoints in each flow guide.

### backward compatibility
- document migration notes for breaking flow changes.

## 6. examples and usage
### code snippets
- not applicable.

### integration scenarios
- onboarding and release planning.

### cli commands
- see individual flow guides.

## 7. troubleshooting and faqs
### common errors
- outdated flow assumptions.

### debugging tips
- verify flow against live endpoints and current code paths.

### performance tuning
- capture bottlenecks in flow-specific docs.

## 8. change log and versioning
### recent updates
- playbook index standardized.

### version compatibility
- process documentation only.
