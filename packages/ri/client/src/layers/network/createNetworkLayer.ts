import { createWorld } from "@latticexyz/recs";
import { setupContracts, setupDevSystems } from "./setup";
import { createActionSystem, defineCoordComponent, defineStringComponent } from "@latticexyz/std-client";
import { GameConfig } from "./config";
import { Coord } from "@latticexyz/utils";
import { BigNumber } from "ethers";

/**
 * The Network layer is the lowest layer in the client architecture.
 * Its purpose is to synchronize the client components with the contract components.
 */
export async function createNetworkLayer(config: GameConfig) {
  console.log("Network config", config);

  // --- WORLD ----------------------------------------------------------------------
  const world = createWorld();

  // --- COMPONENTS -----------------------------------------------------------------
  const components = {
    Position: defineCoordComponent(world, { id: "Position", metadata: { contractId: "ember.component.position" } }),
    CarriedBy: defineStringComponent(world, { id: "CarriedBy", metadata: { contractId: "ember.component.carriedBy" } }),
    Collectable: defineStringComponent(world, {
      id: "Collectable",
      metadata: { contractId: "ember.component.collectable" },
    }),
    Wallet: defineStringComponent(world, { id: "Wallet", metadata: { contractId: "ember.component.wallet" } }),
  };

  // --- SETUP ----------------------------------------------------------------------
  const { txQueue, systems, txReduced$, network, startSync, encoders } = await setupContracts(
    config,
    world,
    components
  );

  // --- ACTION SYSTEM --------------------------------------------------------------
  const actions = createActionSystem(world, txReduced$);

  // --- API ------------------------------------------------------------------------
  function move(id: string, coord: Coord) {
    systems["ember.system.move"].executeTyped(BigNumber.from(id), coord);
  }

  function kidnap(coord: Coord) {
    systems["ember.system.catch"].executeTyped(coord);
  }

  function spawnCollectable(coord: Coord) {
    systems["ember.system.spawnCoin"].executeTyped(coord);
  }

  function collect(id: string) {
    systems["ember.system.collect"].executeTyped(BigNumber.from(id));
  }

  // --- CONTEXT --------------------------------------------------------------------
  const context = {
    world,
    components,
    txQueue,
    systems,
    txReduced$,
    startSync,
    network,
    actions,
    api: { move, kidnap, spawnCollectable, collect },
    dev: setupDevSystems(world, encoders, systems),
  };

  return context;
}
