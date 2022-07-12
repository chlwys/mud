// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;
import { ISystem } from "solecs/interfaces/ISystem.sol";
import { IWorld } from "solecs/interfaces/IWorld.sol";
import { IUint256Component } from "solecs/interfaces/IUint256Component.sol";
import { IComponent } from "solecs/interfaces/IComponent.sol";
import { getAddressById } from "solecs/utils.sol";

import { LibECS } from "std-contracts/libraries/LibECS.sol";

import { LibUtils } from "../libraries/LibUtils.sol";
import { LibStamina } from "../libraries/LibStamina.sol";
import { LibPrototype } from "../libraries/LibPrototype.sol";

import { PositionComponent, ID as PositionComponentID, Coord } from "../components/PositionComponent.sol";
import { StaminaComponent, ID as StaminaComponentID } from "../components/StaminaComponent.sol";
import { LastActionTurnComponent, ID as LastActionTurnComponentID } from "../components/LastActionTurnComponent.sol";
import { GameConfigComponent, ID as GameConfigComponentID } from "../components/GameConfigComponent.sol";
import { MovableComponent, ID as MovableComponentID } from "../components/MovableComponent.sol";
import { UntraversableComponent, ID as UntraversableComponentID } from "../components/UntraversableComponent.sol";
import { OwnedByComponent, ID as OwnedByComponentID } from "../components/OwnedByComponent.sol";
import { FactoryComponent, Factory, ID as FactoryComponentID } from "../components/FactoryComponent.sol";

uint256 constant ID = uint256(keccak256("ember.system.factory"));

contract FactorySystem is ISystem {
  IUint256Component components;
  IWorld world;

  constructor(IUint256Component _components, IWorld _world) {
    components = _components;
    world = _world;
  }

  function requirement(bytes memory arguments) public view returns (bytes memory) {
    (uint256 builderId, uint256 prototypeId, Coord memory position) = abi.decode(arguments, (uint256, uint256, Coord));

    FactoryComponent factoryComponent = FactoryComponent(getAddressById(components, FactoryComponentID));
    require(factoryComponent.has(builderId), "no factory");

    Factory memory factory = factoryComponent.getValue(builderId);

    bool ableToBuildPrototype = false;
    for (uint256 i = 0; i < factory.prototypeIds.length; i++) {
      if (factory.prototypeIds[i] == prototypeId) {
        ableToBuildPrototype = true;
      }
    }
    require(ableToBuildPrototype, "unable to build");

    OwnedByComponent ownedByComponent = OwnedByComponent(getAddressById(components, OwnedByComponentID));
    require(LibECS.isOwnedByCaller(ownedByComponent, builderId), "you don't own this entity");

    uint256 ownerId = LibECS.resolveRelationshipChain(ownedByComponent, builderId);

    PositionComponent positionComponent = PositionComponent(getAddressById(components, PositionComponentID));
    require(LibUtils.manhattan(positionComponent.getValue(builderId), position) == 1, "not adjacent");

    StaminaComponent staminaComponent = StaminaComponent(getAddressById(components, StaminaComponentID));
    require(staminaComponent.has(builderId), "entity has no stamina");

    LastActionTurnComponent lastActionTurnComponent = LastActionTurnComponent(
      getAddressById(components, LastActionTurnComponentID)
    );
    require(lastActionTurnComponent.has(builderId), "entity has no last action turn");

    return abi.encode(builderId, prototypeId, position, ownerId);
  }

  function execute(bytes memory arguments) public returns (bytes memory) {
    (uint256 builderId, uint256 prototypeId, Coord memory position, uint256 ownerId) = abi.decode(
      requirement(arguments),
      (uint256, uint256, Coord, uint256)
    );

    uint256 newEntityId = LibPrototype.copyPrototype(components, world, prototypeId);

    OwnedByComponent(getAddressById(components, OwnedByComponentID)).set(newEntityId, ownerId);
    PositionComponent(getAddressById(components, PositionComponentID)).set(newEntityId, position);
    LastActionTurnComponent(getAddressById(components, LastActionTurnComponentID)).set(
      newEntityId,
      LibStamina.getCurrentTurn(components)
    );

    LibStamina.modifyStamina(components, builderId, -5);
  }

  function requirementTyped(
    uint256 builderId,
    uint256 prototypeId,
    Coord memory position
  ) public view returns (bytes memory) {
    return requirement(abi.encode(builderId, prototypeId, position));
  }

  function executeTyped(
    uint256 builderId,
    uint256 prototypeId,
    Coord memory position
  ) public returns (bytes memory) {
    return execute(abi.encode(builderId, prototypeId, position));
  }
}
