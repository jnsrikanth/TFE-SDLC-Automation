import argparse
import sys
import os

# Add project root to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from agents.orchestrator import OrchestratorAgent

def main():
    parser = argparse.ArgumentParser(description="Level 4 Terraform SDLC Automation Agent")
    parser.add_argument("--requirements", type=str, required=True, help="High-level requirements for the module")
    
    args = parser.parse_args()
    
    orchestrator = OrchestratorAgent()
    orchestrator.run(args.requirements)

if __name__ == "__main__":
    main()
