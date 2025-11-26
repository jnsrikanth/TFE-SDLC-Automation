import argparse
import sys
import os

# Add project root to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import hydra
from omegaconf import DictConfig, OmegaConf
from agents.orchestrator import OrchestratorAgent

@hydra.main(version_base=None, config_path="conf", config_name="config")
def main(cfg: DictConfig):
    print(OmegaConf.to_yaml(cfg))
    
    # Requirements passed via CLI override or prompt
    # In Hydra, we can pass requirements="My Req"
    # But for now let's assume it's passed as a config override or we ask for it if missing
    
    requirements = cfg.get("requirements", "Standard AKS Cluster")
    
    orchestrator = OrchestratorAgent(cfg)
    orchestrator.run(requirements)

if __name__ == "__main__":
    main()
