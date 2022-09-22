// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;
import "solecs/System.sol";
import { IWorld } from "solecs/interfaces/IWorld.sol";
import { IUint256Component } from "solecs/interfaces/IUint256Component.sol";
import { IComponent } from "solecs/interfaces/IComponent.sol";
import { getAddressById, addressToEntity } from "solecs/utils.sol";

import { PositionComponent, ID as PositionComponentID, Coord } from "../components/PositionComponent.sol";
import { MineComponent, ID as MineComponentID } from "../components/MineComponent.sol";
import { ScoreComponent, ID as ScoreComponentID } from "../components/ScoreComponent.sol";

uint256 constant ID = uint256(keccak256("ember.system.try"));

contract TrySystem is System {
  constructor(IUint256Component _components, IWorld _world) System(_components, _world) {}

  function execute(bytes memory arguments) public returns (bytes memory) {
    Coord memory targetPosition = abi.decode(arguments, (Coord));

    PositionComponent position = PositionComponent(getAddressById(components, PositionComponentID));
    MineComponent mine = MineComponent(getAddressById(components, MineComponentID));
    ScoreComponent score = ScoreComponent(getAddressById(components, ScoreComponentID));

    uint256 cScore;
    if (score.has(addressToEntity(msg.sender))) {
      cScore = score.getValue(addressToEntity(msg.sender));
    }

    uint256[] memory entities = position.getEntitiesWithValue(targetPosition);

    if (entities.length != 0) {
      if (mine.has(entities[0])) {
        // lose!
        score.set(addressToEntity(msg.sender), 0);
      } else {
        score.set(addressToEntity(msg.sender), cScore + 1);
      }
    } else {
      score.set(addressToEntity(msg.sender), cScore + 1);
    }
  }

  function executeTyped(Coord memory targetPosition) public returns (bytes memory) {
    return execute(abi.encode(targetPosition));
  }
}
