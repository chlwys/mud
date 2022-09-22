// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;
import "solecs/System.sol";
import { IWorld } from "solecs/interfaces/IWorld.sol";
import { IUint256Component } from "solecs/interfaces/IUint256Component.sol";
import { IComponent } from "solecs/interfaces/IComponent.sol";
import { getAddressById } from "solecs/utils.sol";

import { PositionComponent, ID as PositionComponentID, Coord } from "../components/PositionComponent.sol";
import { MineComponent, ID as MineComponentID } from "../components/MineComponent.sol";
import { AdjComponent, ID as AdjComponentID } from "../components/AdjComponent.sol";

uint256 constant ID = uint256(keccak256("ember.system.init"));

contract InitSystem is System {
  constructor(IUint256Component _components, IWorld _world) System(_components, _world) {}

  function execute(bytes memory arguments) public returns (bytes memory) {
    uint256 count;
    uint256 randomSeed = uint256(block.timestamp);

    PositionComponent position = PositionComponent(getAddressById(components, PositionComponentID));
    MineComponent mine = MineComponent(getAddressById(components, MineComponentID));
    AdjComponent adj = AdjComponent(getAddressById(components, AdjComponentID));

    uint256 currentIndex;

    for (uint256 i; i < 10; i++) {
      currentIndex += (randomSeed % 20) + 1;
      randomSeed = randomSeed % 10;

      int32 xVal = int32(int256(currentIndex / 20 + 1));
      int32 yVal = int32(int256((currentIndex % 20) + 1));

      Coord memory coords = Coord(xVal, yVal);
      mine.set(i);
      position.set(i, coords);
    }

    uint256 cId = 10;
    for (uint256 i; i < 10; i++) {
      Coord memory cMine = position.getValue(i);
      for (int32 x; x < 3; x++) {
        for (int32 y; y < 3; y++) {
          Coord memory curCoord = Coord(cMine.x + x - 1, cMine.y + y - 1);
          uint256[] memory present = position.getEntitiesWithValue(curCoord);

          if (present.length == 0) {
            adj.set(cId, 1);
            position.set(cId, curCoord);
            cId++;
          } else if (adj.has(present[0])) {
            adj.set(present[0], adj.getValue(present[0]) + 1);
          }
        }
      }
    }
  }

  function executeTyped() public returns (bytes memory) {
    return execute(abi.encode());
  }
}
