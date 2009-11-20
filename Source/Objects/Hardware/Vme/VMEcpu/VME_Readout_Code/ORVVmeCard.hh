#ifndef _ORVVmeCard_hh_
#define _ORVVmeCard_hh_

#include <set>
#include "ORVCard.hh"


class TUVMEDevice;
class ORVVmeCard : public ORVCard 
{
   public:
       ORVVmeCard(SBC_card_info* card_info);
       virtual ~ORVVmeCard(); 

    protected:
       static int32_t DMARead(uint32_t vme_address,
                              uint32_t address_modifier,
                              uint32_t data_width,
                              uint8_t* buffer,
                              uint32_t number_of_bytes,
                              bool auto_increment = true);

        static int32_t DMAWrite(uint32_t vme_address,
                                uint32_t address_modifier,
                                uint32_t data_width,
                                uint8_t* buffer,
                                uint32_t number_of_bytes,
                                bool auto_increment = true);
           
       static int32_t VMERead(uint32_t vme_address,
                              uint32_t address_modifier,
                              uint32_t data_width,
                              uint8_t* buffer,
                              uint32_t number_of_bytes);

       static int32_t VMEWrite(uint32_t vme_address,
                               uint32_t address_modifier,
                               uint32_t data_width,
                               uint8_t* buffer,
                               uint32_t number_of_bytes);

       static int32_t VMERead(uint32_t vme_address,
                              uint32_t address_modifier,
                              uint32_t data_width,
                              uint32_t& buffer);
       static int32_t VMERead(uint32_t vme_address,
                              uint32_t address_modifier,
                              uint32_t data_width,
                              uint16_t& buffer);
       static int32_t VMERead(uint32_t vme_address,
                              uint32_t address_modifier,
                              uint32_t data_width,
                              uint8_t& buffer);

       static int32_t VMEWrite(uint32_t vme_address,
                               uint32_t address_modifier,
                               uint32_t data_width,
                               uint32_t buffer);
       static int32_t VMEWrite(uint32_t vme_address,
                               uint32_t address_modifier,
                               uint32_t data_width,
                               uint16_t buffer);
       static int32_t VMEWrite(uint32_t vme_address,
                               uint32_t address_modifier,
                               uint32_t data_width,
                               uint8_t buffer);


    private:
        static TUVMEDevice* fDevice; 
        static std::set<ORVCard*> fAllDevices; 
};
 #endif /* _ORVVmeCard_hh_*/
